package Reflex::Role::Reactive;

use Moose::Role;

use Scalar::Util qw(weaken blessed);
use Carp qw(carp croak);
use Reflex;
use Reflex::Callback::Promise;
use Reflex::Callback::CodeRef;

END {
	#warn join "; ", keys %watchers;
	#warn join "; ", keys %watchings;
}

our @CARP_NOT = (__PACKAGE__);

# Singleton POE::Session.
# TODO - Extract the POE bits into another role if we want to support
# other event loops at the top level rather than beneath POE.

# TODO - How to prevent these from being redefined?
# TODO - Such as if POE is loaded elsewhere first?
#
#sub POE::Kernel::ASSERT_DEFAULT () { 1 }
#sub POE::Kernel::CATCH_EXCEPTIONS () { 0 }
#sub POE::Kernel::USE_SIGCHLD () { 1 }

use POE;
use Reflex::POE::Session;

# Disable a warning.
POE::Kernel->run();

my %session_object_count;

my $singleton_session_id = POE::Session->create(
	inline_states => {
		# Make the session conveniently accessible.
		# Although we're using the $singleton_session_id, so why bother?

		_start => sub {
			# No-op to satisfy assertions.
			undef;
		},
		_stop => sub {
			# No-op to satisfy assertions.
			undef;
		},

		### Timer manipulators and callbacks.

		timer_due => sub {
			my $envelope = $_[ARG0];
			my ($cb_object, $cb_method) = @$envelope;
			$cb_object->$cb_method({});
		},

		### I/O manipulators and callbacks.

		select_ready => sub {
			my ($handle, $envelope, $mode) = @_[ARG0, ARG2];
			my ($cb_object, $cb_method) = @$envelope;
			$cb_object->$cb_method({ handle => $handle });
		},

		### Signals.

		signal_happened => sub {
			my $signal_class = pop @_;
			$signal_class->deliver(@_[ARG0..$#_]);
		},

		### Cross-session emit() is converted into these events.

		deliver_callback => sub {
			my ($callback, $args) = @_[ARG0, ARG1];
			$callback->deliver($args);
		},

		# call_gate() uses this to call methods in the right session.

		call_gate_method => sub {
			my ($object, $method, @args) = @_[ARG0..$#_];
			return $object->$method(@args);
		},

		call_gate_coderef => sub {
			my ($coderef, @args) = @_[ARG0..$#_];
			return $coderef->(@args);
		},

		# Catch dynamic events.

		_default => sub {
			my ($event, $args) = @_[ARG0, ARG1];

			return $event->deliver($args) if (
				"$event" =~ /^Reflex::POE::Event(?:::|=)/
			);

			return if Reflex::POE::Session->deliver($_[SENDER]->ID, $event, $args);

			# Unhandled event.
			# TODO - Should anything special be done in this case?
		},

		### Support POE::Wheel classes.

		# Deliver to wheels based on the wheel ID.  Different wheels pass
		# their IDs in different ARGn offsets, so we need a few of these.
		wheel_event_0 => sub {
			$_[CALLER_FILE] =~ m{/([^/.]+)\.pm};
			"Reflex::POE::Wheel:\:$1"->deliver(0, @_[ARG0..$#_]);
		},
		wheel_event_1 => sub {
			$_[CALLER_FILE] =~ m{/([^/.]+)\.pm};
			"Reflex::POE::Wheel:\:$1"->deliver(1, @_[ARG0..$#_]);
		},
		wheel_event_2 => sub {
			$_[CALLER_FILE] =~ m{/([^/.]+)\.pm};
			"Reflex::POE::Wheel:\:$1"->deliver(2, @_[ARG0..$#_]);
		},
		wheel_event_3 => sub {
			$_[CALLER_FILE] =~ m{/([^/.]+)\.pm};
			"Reflex::POE::Wheel:\:$1"->deliver(3, @_[ARG0..$#_]);
		},
		wheel_event_4 => sub {
			$_[CALLER_FILE] =~ m{/([^/.]+)\.pm};
			"Reflex::POE::Wheel:\:$1"->deliver(4, @_[ARG0..$#_]);
		},
	},
)->ID();

has session_id => (
	isa     => 'Str',
	is      => 'ro',
	default => $singleton_session_id,
);

# What's watching me.
# watchers()->{$watcher} = \@callbacks
has watchers => (
	isa     => 'HashRef',
	is      => 'rw',
	default => sub { {} },
);

# What's watching me.
# watchers_by_event()->{$event}->{$watcher} = \@callbacks
has watchers_by_event => (
	isa     => 'HashRef',
	is      => 'rw',
	default => sub { {} },
);

# What I'm watching.
# watched_objects()->{$watched}->{$event} = \@interests
has watched_object_events => (
	isa     => 'HashRef',
	is      => 'rw',
	default => sub { {} },
);

has watched_objects => (
	isa     => 'HashRef',
	is      => 'rw',
	default => sub { {} },
);

# TODO - Needs to be class, not object based!
#has role => (
#	is      => 'ro',
#	isa     => 'Str',
#	default => sub {
#		my $self = shift;
#		my $role = ref($self);
#		$role =~ s/^Reflex:://;
#		$role =~ tr[a-zA-Z0-9][_]cs;
#		return lc $role;
#	},
#);

has promise => (
	is => 'rw',
	isa => 'Reflex::Callback::Promise',
);

has emits_seen => (
	is      => 'rw',
	isa     => 'HashRef[Str]',
	default => sub { {} },
);

# Base class.

sub BUILD {}
after BUILD => sub {
	my ($self, $args) = @_;

	# Set up all emitters and watchers.

	foreach my $setup (
		grep {
			$_->does('Reflex::Trait::EmitsOnChange') || $_->does('Reflex::Trait::Observed')
		}
		$self->meta()->get_all_attributes()
	) {
		my $callback = $setup->setup();
		next unless defined $callback;

		# TODO - Better way to detect CodeRef?
		if (ref($callback) eq "CODE") {
			my $member = $setup->name();
			$self->$member( $callback->($self) ); # TODO - Proper parameters!
			next;
		}

		# TODO - Better way to detect HashRef?
		if (ref($callback) eq "HASH") {
			my $member = $setup->name();

			my @types = (
				grep { $_ ne "Undef" }
				split /\s*\|\s*/,
				$setup->type_constraint()
			);

			croak "Hashref 'setup' can't determine the class from 'isa'" if (
				@types < 1
			);

			croak "Hashref 'setup' can't set up more than one class from 'isa'" if (
				@types > 1
			);

			my $type = $types[0];
			$self->$member( $type->new($callback) );
			next;
		}

		croak "Unknown 'setup' value: $callback";
	}

	# Discrete callbacks.

	CALLBACK: while (my ($param, $value) = each %$args) {
		next unless $param =~ /^on_(\S+)/;

		if (ref($value) eq "CODE") {
			$value = Reflex::Callback::CodeRef->new(
				object    => $self,
				code_ref  => $value,
			);
		}

		# There is an object, so we have a watcher.
		if ($value->object()) {
			$value->object()->watch($self, $1 => $value);
			next CALLBACK;
		}

		# TODO - Who is the watcher?
		# TODO - Optimization!  watch() takes multiple event/callback
		# pairs.  We can combine them into a hash and call watch() once.
		$self->watch($self, $1 => $value);
		next CALLBACK;
	}

	# The session has an object.
	$session_object_count{$self->session_id()}++;
};

# TODO - Does Moose have sugar for passing named parameters?

# Self is watching something.  Register the interest with self.
sub watch {
	my ($self, $watched, %callbacks) = @_;

	while (my ($event, $callback) = each %callbacks) {
		$event =~ s/^on_//;

		my $interest = {
			callback  => $callback,
			event     => $event,
			watched   => $watched,
		};

		weaken $interest->{watched};
		unless (exists $self->watched_objects()->{$watched}) {
			$self->watched_objects()->{$watched} = $watched;
			weaken $self->watched_objects()->{$watched};

			# Keep this object's session alive.
			$POE::Kernel::poe_kernel->refcount_increment($self->session_id, "in_use");
		}

		push @{$self->watched_object_events()->{$watched}->{$event}}, $interest;

		# Tell what I'm watching that it's being watched.

		$watched->_is_watched($self, $event, $callback);
	}

	undef;
}

# Self is no longer being watched.  Remove interest from self.
sub _stop_watchers {
	my ($self, $watcher, $events) = @_;

	my @events = @{$events || []};

	unless (@events) {
		my %events = (
			map { $_->{event} => $_->{event} }
			map { @$_ }
			values %{$self->watchers()}
		);
		@events = keys %events;
	}

	foreach my $event (@events) {
		delete $self->watchers_by_event()->{$event}->{$watcher};
		delete $self->watchers_by_event()->{$event} unless (
			scalar keys %{$self->watchers_by_event()->{$event}}
		);
		pop @{$self->watchers()->{$watcher}};
	}

	delete $self->watchers()->{$watcher} unless (
		exists $self->watchers()->{$watcher} and
		@{$self->watchers()->{$watcher}}
	);
}

sub _is_watched {
	my ($self, $watcher, $event, $callback) = @_;

	my $interest = {
		callback  => $callback,
		event     => $event,
		watcher   => $watcher ,
	};
	weaken $interest->{watcher};

	push @{$self->watchers_by_event()->{$event}->{$watcher}}, $interest;
	push @{$self->watchers()->{$watcher}}, $interest;
}

sub emit {
	my ($self, @args) = @_;

	# TODO - Is there a better way to check parameters?  Checking them
	# in custom code is tedious.  Calling check_args() is relatively
	# slow.  Can we have our peanut butter and our chocolate together?

	my $args = $self->check_args(
		\@args,
		[ 'event' ],
		[ 'args' ],
	);

	my $event         = $args->{event};
	my $callback_args = $args->{args} || {};

	# TODO - Needs consideration:
	# TODO - Weaken?
	# TODO - Underscores for Reflex parameters?
	# TODO - Must be a hash reference.  Would be nice if non-hashref
	# errors were pushed to the caller.
	$callback_args->{_sender} = $self;

	# Look for self-handling of the event.
	# TODO - can() calls are also candidates for caching.
	# (AKA: Cache as cache can()?)

	my $caller_role = caller();
	$caller_role =~ s/^Reflex::(?:Role::)?//;
	$caller_role =~ tr[a-zA-Z0-9][_]cs;

	my $self_method = "on_" . lc($caller_role) . "_" . $event;
	#warn $self_method;
	if ($self->can($self_method)) {
		# Already seen this; we're recursing!  Break it up!
		if ($self->emits_seen()->{"$self -> $self_method"}) {
			$self->emits_seen({});
			$poe_kernel->post(
				$self->session_id(), 'call_gate_method',
				$self, $self_method, $callback_args
			);
			return;
		}

		# Not recursing yet.  Give it a try!
		$self->emits_seen()->{"$self -> $self_method"} = 1;
		$self->$self_method($callback_args);
		return;
	}

	# This event isn't watched.

	my $deliver_event = $event;
	unless (exists $self->watchers_by_event()->{$deliver_event}) {
		if ($self->promise()) {
			$self->promise()->deliver($event, $callback_args);
			return;
		}

		$deliver_event = "promise";
		return unless exists $self->watchers_by_event()->{$deliver_event};
		# Fall through.
	}

	# This event is watched.  Broadcast it to watchers.
	# TODO - Accessor calls are expensive.  Optimize them away.

	while (
		my ($watcher, $callbacks) = each %{
			$self->watchers_by_event()->{$deliver_event}
		}
	) {
		CALLBACK: foreach my $callback_rec (@$callbacks) {
			my $callback = $callback_rec->{callback};

			# Same session.  Just deliver it.
			# TODO - Break recursive callbacks?
			if (
				$callback_rec->{watcher}->session_id() eq
				$POE::Kernel::poe_kernel->get_active_session()->ID
			) {
				$callback->deliver($event, $callback_args);
				next CALLBACK;
			}

			# Different session.  Post it through.
			$poe_kernel->post(
				$callback_rec->{watcher}->session_id(), 'deliver_callback',
				$callback, $callback_args,
				$callback_rec->{watcher}, $self, # keep objects alive a bit
			);
		}
	}
}

sub deliver {
	die "@_";
}

sub check_args {
	my ($self, $args, $required, $optional) = @_;

	if (ref($args) eq 'ARRAY') {
		croak "constructor parameters must be key/value pairs" if @$args % 2;
		$args = { @$args };
	}

	unless (ref($args) eq 'HASH') {
		croak "constructor parameters are an unknown type";
	}

	my @error;

	if (my @missing = grep { !exists($args->{$_}) } @$required) {
		push @error, "required parameters are missing: @missing";
	}

	my %all = map { $_ => 1 } @$required, @$optional;
	if (my @excess = grep { !exists($all{$_}) } keys %$args) {
		push @error, "unknown parameters: @excess";
	}

	return $args unless @error;
	croak join "; ", @error;
}

# An object is demolished.
# The filehash should destroy everything it watches.
# All interests of this object must be manually demolished.

sub _shutdown {
	my $self = shift;

	# Anything that was watching us, no longer is.

	my %watchers = (
		map { $_->{watcher} => $_->{watcher} }
		map { @$_ }
		values %{$self->watchers()}
	);

	foreach my $watcher (values %watchers) {
		$watcher->ignore($self);
	}

	# Anything we were watching, no longer is being.

	foreach my $watched (values %{$self->watched_objects()}) {
		$self->ignore($watched);
	}
}

sub DEMOLISH {
	my $self = shift;
	$self->_shutdown();
}

sub ignore {
	my ($self, $watched, @events) = @_;

	croak "ignore requires at least an object" unless defined $watched;

	if (@events) {
		delete @{$self->watched_object_events()->{$watched}}{@events};
		unless (scalar keys %{$self->watched_object_events()->{$watched}}) {
			delete $self->watched_object_events()->{$watched};
			delete $self->watched_objects()->{$watched};

			# Decrement the session's use count.
			$POE::Kernel::poe_kernel->refcount_decrement($self->session_id, "in_use");
		}
		$watched->_stop_watchers($self, \@events);
	}
	else {
		use Carp qw(cluck); cluck "whaaaa" unless defined $watched;
		delete $self->watched_object_events()->{$watched};
		delete $self->watched_objects()->{$watched};
		$watched->_stop_watchers($self);

		# Decrement the session's use count.
		$POE::Kernel::poe_kernel->refcount_decrement($self->session_id, "in_use");
	}
}

# http://en.wikipedia.org/wiki/Call_gate

sub call_gate {
	my ($self, $method) = @_;

	return 1 if (
		$self->session_id() eq $POE::Kernel::poe_kernel->get_active_session()->ID()
	);

	$POE::Kernel::poe_kernel->call(
		$self->session_id(), "call_gate_method", $self, $method, @_[2..$#_]
	);
	return 0;
}

sub run_within_session {
	my ($self, $method) = @_;

	if (
		$self->session_id() eq $POE::Kernel::poe_kernel->get_active_session()->ID()
	) {
		if (ref($method) =~ /^CODE/) {
			return $method->(@_[2..$#_]);
		}
		return $self->$method(@_[2..$#_]);
	}

	if (ref($method) =~ /^CODE/) {
		return $POE::Kernel::poe_kernel->call(
			$self->session_id(), "call_gate_coderef", $method, @_[2..$#_]
		);
	}

	return $POE::Kernel::poe_kernel->call(
		$self->session_id(), "call_gate_method", $self, $method, @_[2..$#_]
	);
}

sub run_all {
	POE::Kernel->run();
}

sub next {
	my $self = shift;

	$self->promise() || $self->promise(Reflex::Callback::Promise->new());
	return $self->promise()->next();
}

1;

__END__

=head1 NAME

Reflex::Role::Reactive - Make an object reactive (aka, event driven).

=head1 SYNOPSIS

With Moose:

	package Object;
	use Moose;
	with 'Reflex::Role::Reactive';

	...;

	1;

Without Moose:

	# Sorry, roles are defined and composed using Moose.
	# However, Reflex::Base may be used the old fashioned way.

=head1 DESCRIPTION

Reflex::Role::Reactive provides Reflex's event-driven features to
other objects.  It provides public methods that help use reactive
objects and to write them.

=head1 Public Attributes

=head2 session_id

Each Reflex object is associated with a POE session, although a single
session may (and usually does) drive several objects.  Reflex objects
expose session_id() for times where it's important to know which
session owns them.  Usually when interfacing between Reflex and POE.

session_id() is rarely needed, especially since Reflex provides helper
classes for working with POE modules.  Please see one or more of:
L<Reflex::POE::Event>, L<Reflex::POE::Postback>,
L<Reflex::POE::Session>, L<Reflex::POE::Wheel> and
L<Reflex::POE::Wheel::Run>.

	sub method {
		my $self = shift;
		print(
			"I, $self, am driven by POE::Sesson ID ",
			$self->session_id(), "\n"
		);
	}

=head2 watch

watch() allows one object (the watcher) to register interest in
events emitted by another.  It takes three named parameters:
"watched" must contain a Reflex object (either a Reflex::Role::Reactive
consumer, or a Reflex::Base subclass).  "event" contains the name of
an event that the watched object emits.  Finally, "callback" contains
a Reflex::Callback that will be invoked when the event occurs.

	use Reflex::Callbacks(cb_method);

	$self->watch(
		watched   => $an_object_maybe_myself,
		event     => "occurrence",
		callback  => cb_method($self, "method_name"),
	);

=head2 emit

Emit an event.  This triggers callbacks for anything waiting for the
event from the object that emitted it.  Callback invocation is often
synchronous, but this isn't guaranteed.  Later versions of Reflex will
support remote objects, where the emitter and callback may not be in
the same room.

Emit takes two named parameters so far: "event" names the event being
emitted and is required.  "args" allows data to be passed along with
the event, and it should contain a hashref of named values.

Reflex::Stream emits a "failure" event when things don't go as
planned:

	sub _emit_failure {
		my ($self, $errfun) = @_;

		$self->emit(
			event => "failure",
			args  => {
				data    => undef,
				errnum  => ($!+0),
				errstr  => "$!",
				errfun  => $errfun,
			},
		);

		return;
	}

=head2 ignore

The ignore() method tells Reflex that one object has lost interest in
events from another.  It requires at least one parameter, the object
to be ignored.  Additional parameters may name specific events to
ignore.

Ignore an object entirely:

	$self->ignore($an_object_maybe_myself);

Ignore just specific events:

	my @events = qw(success failure);
	$self->ignore($an_object_maybe_myself, @events);

An object may destruct while it's being watched and/or is watching
other objects.  DEMOLISH will ensure that all watchers related to the
outgoing object are cleaned up.  Therefore it's usually more
convenient to just destroy things when done with them.

=head2 call_gate

call_gate() is a helper that ensures a method is called from the same
POE::Session instance that owns its object.  It's mainly of interest
to authors of POE modules and their Reflex interfaces.  Other users
may never need it.

POE consumers often return responses to the sessions that made
requests.  For Reflex objects to receive these responses, they must
first send their requests from the right sessions.  call_gate() helps
by ensuring the proper session is active.

call_gate() takes one required positional parameter: the name of the
method calling call_gate().  Any other parameters are passed back to
the method, re-creating @_ as it was originally.

call_gate() immediately returns 1 if it's called from the correct
session.  Otherwise it re-invokes the method in the proper session and
returns 0.

It's important to put call_gate() first in methods that need it, and
for them to return immediately fi call_gate() returns false.

This method from Reflex::Signal makes sure the signal is watched by
the same session that owns the object doing the watching:

	sub start_watching {
		my $self = shift;
		return unless $self->call_gate("start_watching");
		$POE::Kernel::poe_kernel->sig($self->name(), "signal_happened");
	}

=head2 run_within_session

run_within_session() is another helper method to ensure some code is
running in the POE session that POE modules may expect.  It takes one
required positional parameter, a code reference to invoke or the name
of a method to call on $self.  Any other parameters are passed to the
code that will be executed.

For example the IRC bot in eg/eg-13-irc-bot.pl wants to register
callbacks with POE::Component::IRC.  It calls a couple $bot->yield()
methods within the object's session.  This helps the component know
where to send its responses:

	sub BUILD {
		my $self = shift;

		# Set up $self->component() to contain
		# a POE::Component::IRC object.

		...;

		# Register this object's interest in the component,
		# via the session that owns this object.
		$self->run_within_session(
			sub {
				$self->component()->yield(register => "all");
				$self->component()->yield(connect  => {});
			}
		)
	}

=head2 next

Wait for the next event promised by an object.  Requires the object to
emit an event that isn't already explicitly handled.  All Reflex
objects will run in the background while next() blocks.

next() returns the next event emitted by an object.  Objects cease to
run while your code processes the event, so be quick about it.

Here's most of eg/eg-32-promise-tiny.pl, which shows how to next() on
events from a Reflex::Interval.

	use Reflex::Interval;

	my $t = Reflex::Interval->new(
		interval    => 1,
		auto_repeat => 1,
	);

	while (my $event = $t->next()) {
		print "next() returned event '$event->{name}'...\n";
	}

It's tempting to rename this method next().

=head2 run_all

Run all active Reflex objects until they destruct.  This will not
return discrete events, like next() does.  It will not return at all
before the program is done.  It returns no meaningful value yet.

run_all() is useful when you don't care to next() on objects
individually.  You just want the program to run 'til it's done.

=head1 EXAMPLES

Many of the examples in the distribution's eg directory use Reflex
objects.  Explore and enjoy!

=head1 SEE ALSO

L<Moose::Manual::Concepts>

L<Reflex>
L<Reflex::Base>

L<Reflex/ACKNOWLEDGEMENTS>
L<Reflex/ASSISTANCE>
L<Reflex/AUTHORS>
L<Reflex/BUGS>
L<Reflex/BUGS>
L<Reflex/CONTRIBUTORS>
L<Reflex/COPYRIGHT>
L<Reflex/LICENSE>
L<Reflex/TODO>

=cut
