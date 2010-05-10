package Reflex::Role::Object;

use Moose::Role;

use Scalar::Util qw(weaken blessed);
use Carp qw(croak);

END {
	#warn join "; ", keys %observers;
	#warn join "; ", keys %observations;
}

our @CARP_NOT = (__PACKAGE__);

# Singleton POE::Session.
# TODO - Extract the POE bits into another role.

# TODO - How to prevent this from being redefined?
#sub POE::Kernel::ASSERT_DEFAULT () { 1 }

sub POE::Kernel::CATCH_EXCEPTIONS () { 0 }
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
			$envelope->[0]->_deliver();
		},

		### I/O manipulators and callbacks.

		select_ready => sub {
			my ($handle, $envelope, $mode) = @_[ARG0, ARG2, ARG3];
			$envelope->[0]->_deliver($handle, $mode, @_[ARG4..$#_]);
		},

		### Signals.

		signal_happened => sub {
			Reflex::Signal->_deliver(@_[ARG0..$#_]);
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
			# TODO - Anything special?
		},

		### Support POE::Wheel classes.

		# Deliver to wheels based on the wheel ID.  Different wheels pass
		# their IDs in different ARGn offsets, so we need a few of these.
		wheel_event_0 => sub {
			$_[CALLER_FILE] =~ m{/([^/.]+)\.pm};
			"Reflex::POE::Wheel:\:$1"->_deliver(0, @_[ARG0..$#_]);
		},
		wheel_event_1 => sub {
			$_[CALLER_FILE] =~ m{/([^/.]+)\.pm};
			"Reflex::POE::Wheel:\:$1"->_deliver(1, @_[ARG0..$#_]);
		},
		wheel_event_2 => sub {
			$_[CALLER_FILE] =~ m{/([^/.]+)\.pm};
			"Reflex::POE::Wheel:\:$1"->_deliver(2, @_[ARG0..$#_]);
		},
		wheel_event_3 => sub {
			$_[CALLER_FILE] =~ m{/([^/.]+)\.pm};
			"Reflex::POE::Wheel:\:$1"->_deliver(3, @_[ARG0..$#_]);
		},
		wheel_event_4 => sub {
			$_[CALLER_FILE] =~ m{/([^/.]+)\.pm};
			"Reflex::POE::Wheel:\:$1"->_deliver(4, @_[ARG0..$#_]);
		},
	},
)->ID();

has session_id => (
	isa     => 'Str',
	is      => 'ro',
	default => $singleton_session_id,
);

# What's watching me.
# watchers()->{$observer} = \@callbacks
has watchers => (
	isa     => 'HashRef',
	is      => 'rw',
	default => sub { {} },
);

# What's watching me.
# watchers_by_event()->{$event}->{$observer} = \@callbacks
has watchers_by_event => (
	isa     => 'HashRef',
	is      => 'rw',
	default => sub { {} },
);

# What I'm watching.
# watched_objects()->{$observed}->{$event} = \@observations
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

has observers => (
	isa     => 'ArrayRef',
	is      => 'rw',
	default => sub { [] },
);

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

sub BUILD {
	my ($self, $args) = @_;

	# Set up all emitters and observers.

	foreach my $setup (
		grep {
			$_->does('Reflex::Trait::Emitter') || $_->does('Reflex::Trait::Observer')
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

	# Known observers.

	foreach my $observer (@{$self->observers()}) {
		my $watcher = shift @$observer;
		$watcher->observe($self, @$observer);
	}

	# Discrete callbacks.

	CALLBACK: while (my ($param, $value) = each %$args) {
		next unless $param =~ /^on_(\S+)/;

		# There is an object, so we have a watcher.
		if ($value->object()) {
			$value->object()->observe($self, $1 => $value);
			next CALLBACK;
		}

		# TODO - Who is the watcher?
		$self->observe($self, $1 => $value);
		next CALLBACK;
	}

	# Clear observers; we're done with them.
	# TODO - Moose probably has a better way of validating parameters.
	$self->observers([]);

	# The session has an object.
	$session_object_count{$self->session_id()}++;
}

# TODO - Does Moose have sugar for passing named parameters?

# Self is being observed.  Register the observation with self.
sub observe {
	my ($self, $observed, %args) = @_;

	while (my ($event, $callback) = each %args) {
		$event =~ s/^on_//;

		my $observation = {
			callback  => $callback,
			event     => $event,
			observed  => $observed,
		};

		weaken $observation->{observed};
		unless (exists $self->watched_objects()->{$observed}) {
			$self->watched_objects()->{$observed} = $observed;
			weaken $self->watched_objects()->{$observed};

			# Keep this object's session alive.
			$POE::Kernel::poe_kernel->refcount_increment($self->session_id, "in_use");
		}

		push @{$self->watched_object_events()->{$observed}->{$event}}, $observation;

		# Tell what I'm watching that it's being observed.

		$observed->_is_observed($self, $event, $callback);
	}

	undef;
}

# Self is no longer being observed.  Remove observations from self.
sub _stop_observers {
	my ($self, $observer, $events) = @_;

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
		delete $self->watchers_by_event()->{$event}->{$observer};
		delete $self->watchers_by_event()->{$event} unless (
			scalar keys %{$self->watchers_by_event()->{$event}}
		);
		pop @{$self->watchers()->{$observer}};
	}

	delete $self->watchers()->{$observer} unless (
		@{$self->watchers()->{$observer}}
	);
}

sub _is_observed {
	my ($self, $observer, $event, $callback) = @_;

	my $observation = {
		callback  => $callback,
		event     => $event,
		observer  => $observer,
	};
	weaken $observation->{observer};

	push @{$self->watchers_by_event()->{$event}->{$observer}}, $observation;
	push @{$self->watchers()->{$observer}}, $observation;
}

sub emit {
	my ($self, @args) = @_;

	# TODO - Checking arguments is tedious, but _check_args() method
	# calls add up.

	my $args = $self->_check_args(
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

	# This event isn't observed.

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

	# This event is observed.  Broadcast it to observers.
	# TODO - Accessor calls are expensive.  Optimize them away.

	while (
		my ($observer, $callbacks) = each %{
			$self->watchers_by_event()->{$deliver_event}
		}
	) {
		CALLBACK: foreach my $callback_rec (@$callbacks) {
			my $callback = $callback_rec->{callback};

			# Same session.  Just deliver it.
			# TODO - Break recursive callbacks?
			if (
				$callback_rec->{observer}->session_id() eq
				$POE::Kernel::poe_kernel->get_active_session()->ID
			) {
				$callback->deliver($event, $callback_args);
				next CALLBACK;
			}

			# Different session.  Post it through.
			$poe_kernel->post(
				$callback_rec->{observer}->session_id(), 'deliver_callback',
				$callback, $callback_args,
				$callback_rec->{observer}, $self, # keep objects alive a bit
			);
		}
	}
}

sub _deliver {
	die "@_";
}

sub _check_args {
	my ($self, $args, $required, $optional) = @_;

	if (ref($args) eq 'ARRAY') {
		croak "constructor parameters must be key/value pairs" if @$args % 2;
		$args = { @$args };
	}

	unless (ref($args) eq 'HASH') {
		croak "constructor parameters are an unknown type";
	}

	my @error;

	my @missing = grep { !exists($args->{$_}) } @$required;
	push @error, "required parameters are missing: @missing" if @missing;

	my %all = map { $_ => 1 } @$required, @$optional;
	my @excess = grep { !exists($all{$_}) } keys %$args;
	push @error, "unknown parameters: @excess" if @excess;

	return $args unless @error;
	croak join "; ", @error;
}

# An object is demolished.
# The filehash should destroy everything it observes.
# All observations of this object must be manually demolished.

sub _shutdown {
	my $self = shift;

	# Anything that was watching us, no longer is.

	my %observers = (
		map { $_->{observer} => $_->{observer} }
		map { @$_ }
		values %{$self->watchers()}
	);

	foreach my $observer (values %observers) {
		$observer->ignore(observed => $self);
	}

	# Anything we were observing, no longer is being.

	foreach my $observed (values %{$self->watched_objects()}) {
		$self->ignore(observed => $observed);
	}
}

sub DEMOLISH {
	my $self = shift;
	$self->_shutdown();
}

sub ignore {
	my ($self, @args) = @_;

	my $args = $self->_check_args(
		\@args,
		[ 'observed' ],
		[ 'events' ],
	);

	my $observed = $args->{observed};
	my @events   = @{$args->{events} || []};

	if (@events) {
		delete @{$self->watched_object_events()->{$observed}}{@events};
		unless (scalar keys %{$self->watched_object_events()->{$observed}}) {
			delete $self->watched_object_events()->{$observed};
			delete $self->watched_objects()->{$observed};

			# Decrement the session's use count.
			$POE::Kernel::poe_kernel->refcount_decrement($self->session_id, "in_use");
		}
		$observed->_stop_observers($self, \@events);
	}
	else {
		use Carp qw(cluck); cluck "whaaaa" unless defined $observed;
		delete $self->watched_object_events()->{$observed};
		delete $self->watched_objects()->{$observed};
		$observed->_stop_observers($self);

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

sub wait {
	my $self = shift;

	$self->promise() || $self->promise(Reflex::Callback::Promise->new());
	return $self->promise()->wait();
}

1;

__END__

=head1 NAME

Reflex::Role::Object - Make an object reactive (aka, event driven).

=head1 SYNOPSIS

With Moose:

	package Object;
	use Moose;
	with 'Reflex::Role::Object';

	...;

	1;

Without Moose:

	# Sorry, roles are defined and composed using Moose.
	# However, Reflex::Object may be used the old fashioned way.

=head1 DESCRIPTION

Reflex::Role::Object provides Reflex's event-driven features to other
objects.  It provides public methods that help use reactive objects
and to write them.

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

=head2 observe

observe() allows one object (the observer) to register interest in
events emitted by another.  It takes three named parameters:
"observed" must contain a Reflex object (either a Reflex::Role::Object
consumer, or a Reflex::Object subclass).  "event" contains the name of
an event that the observed object emits.  Finally, "callback" contains
a Reflex::Callback that will be invoked when the event occurs.

	use Reflex::Callbacks(cb_method);

	$self->observe(
		observed  => $an_object_maybe_myself,
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
events from another.  It takes two named parameters.  "observed" is
required and indicates which object is being ignored.  "events" is an
optional array reference containing zero or more event names to
ignore.

	$self->ignore(
		observed => $an_object_maybe_myself,
		events   => [qw( success failure )],
	);

All events will be ignored if "events" is not specified:

	$self->ignore(
		observed => $an_object_maybe_myself,
	);

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
by ensuring this.

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

=head2 wait

Wait for an object to emit() a promised event.  Requires the object to
emit an event that isn't already explicitly handled.  All Reflex
objects will run in the background while wait() blocks.

wait() returns the next event emitted by an object.  Objects cease to
run while your code processes the event, so be quick about it.

Here's most of eg/eg-32-promise-tiny.pl, which shows how to wait() on
events from a Reflex::Timer.

	use Reflex::Timer;

	my $t = Reflex::Timer->new(
		interval    => 1,
		auto_repeat => 1,
	);

	while (my $event = $t->wait()) {
		print "wait() returned event '$event->{name}'...\n";
	}

It's tempting to rename this method next().

=head2 run_all

Run all active Reflex objects until they destruct.  This will not
return discrete events, like wait() does.  It will not return at all
before the program is done.  It returns no meaningful value yet.

run_all() is useful when you don't care to wait() on objects
individually.  You just want the program to run 'til it's done.

=head1 EXAMPLES

Many of the examples in the distribution's eg directory use Reflex
objects.  Explore and enjoy!

=head1 SEE ALSO

L<Moose::Manual::Concepts>

L<Reflex>
L<Reflex::Object>

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
