#!/usr/bin/env perl

# Agorman's concerns:
#
# 1. This way of doing things seems like I couldn't do $tc->next to get
# the result event.
#
#   a. We can add a new pass_on() that re-emits events without
#   clobbering _sender.  However, this inverts the problem---in some
#   cases we may want _sender to refer to the collection!  The caller
#   should be able to decide.
#
#   b. Add the member to $args when re-emitting an event.  This idea
#   is implemeted in PromiseCollection, below.  It feels like the best
#   option from a design standpoint, but it's also the most tedious
#   and least efficient.  Every layer of an application's stack must
#   re-emit events that are part of its interface.  That's good
#   encapsulation and explicit code.
#
#   Since it's a common thing to do, maybe there can be some
#   shortcuts.  Like "handles" in Moose allows an object's methods to
#   become part of its owner.  Something similar may be done to say an
#   object's events are part of its owner.
#
#   c. We can hack Reflex::Role::Reactive to propagate unhandled
#   emitted events to parents/grandparent/etc. promises.  Too
#   implicit.  "Spooky action at a distance."  I don't like invisible
#   things like this.
#
# 2. Not sure I love $self->result( $args ); inside my TestCollectible
# method. Be nice if it could just get the current state of the
# object.  Using sender doesn't work because the state has (possible)
# changed by the time of the callback.
#
#   I don't know if that would be possible without cloning the object
#   at the time of result().  And then any calls on the clone wouldn't
#   affect the original object that might still be in the collection.
#
#   It might help to think of results as being different types than
#   the objects that create them.  DNS resolvers return IP addresses,
#   not more DNS resolvers.  HTTP user agents return HTTP responses.
#
#   Maybe result() could be renamed response() or output()?
#
# 3. It would be nice if my callback inside the owner class was
# on_foo_event rather than on_event but I don't know of a good way to
# deal with the plural singular thing.
#
#   a. I haven't got to this.  1 & 2 have given me a lot to work on
#   already.

my $collectible_id = 1;

{
	package TestCollectible;
	use Moose;
	with 'Reflex::Role::Collectible';
	extends 'Reflex::Base';  # TODO - Implicit in Reflex::Role::Collectible?
	use Reflex::Trait::Watched;
	use Reflex::Interval;

	has id => (
		is  => 'rw',
		isa => 'Int',
	);

	has count => (
		is => 'rw',
		isa => 'Int',
		default => 0,
	);

	watches timer => (
		is => 'rw',
		isa => 'Maybe[Reflex::Interval]',
		setup => sub {
			Reflex::Interval->new(
				interval => rand() / 10,  # Mixes up the output.
				auto_repeat => 1,
			);
		}
	);

	sub on_timer_tick {
		my $self = shift;

		my $count = $self->count() + 1;
		$self->result({ value => $count });
		if ($count < 9) {
			$self->count($count);
			return;
		}

		$self->timer(undef);
		$self->stopped();
		return;
	}
}

###

{
	package TestCollection;
	use Moose;
	extends 'Reflex::Base';
	use Reflex::Collection;

	has_many foos => (
		handles   => { remember_foo => "remember" },
	);

	sub BUILD {
		my ($self, $args) = @_;

		for (1..9) {
			$self->remember_foo(TestCollectible->new(id => $collectible_id++));
		}
	}

	sub on_result {
		my ($self, $args) = @_;

		my $foo      = $args->{_sender}->get_first_emitter();
		my $value    = $args->{value};
		my $foo_type = ref $foo;
		printf(
			"test collection got a result from %s! id => %s, value => %s\n",
			$foo_type, $foo->id, $value
		);
	}
}

{
	package PromiseCollection;
	use Moose;
	extends 'Reflex::Base';
	use Reflex::Collection;

	has_many foos => (
		handles   => { remember_foo => "remember" },
	);

	sub BUILD {
		my ($self, $args) = @_;

		for (1..9) {
			$self->remember_foo(TestCollectible->new(id => $collectible_id++));
		}
	}

	# 2. TestCollection can include a new "member" parameter when it
	# re-emits events.  "member" points to the collectible object that
	# really sent the event.  Reflex::Role::Reactive is free to clobber
	# _sender.

	sub on_result {
		my ($self, $args) = @_;
		$self->emit( event => "result", args => $args );
	}
}

# By waiting on a promise for TestCollection, we really want to
# receive events from any TestCollectible in the collection.

my $tc = TestCollection->new();
my $tcp = PromiseCollection->new();

while (my $e = $tcp->next) {
	my $sender = $e->{arg}{_sender}->get_first_emitter();
	printf(
		"promise collection got a result of %s! id => %s, value => %s\n",
		ref($sender), $sender->id, $e->{arg}{value}
	);
}

exit;
