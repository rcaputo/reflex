package StageRole;

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

use POE;

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
			$envelope->[0]->_deliver($handle, $mode);
		},

		### Signals.

		signal_happened => sub {
			Signal->_deliver(@_[ARG0..$#_]);
		},

		### Cross-session emit() is converted into these events.

		emit_to_coderef => sub {
			my ($callback, $args) = @_[ARG0, ARG1];
			$callback->($args);
		},

		emit_to_method => sub {
			my ($observer, $method, $args) = @_[ARG0..$#_];
			$observer->$method($args);
		},

		# call_gate() uses this to call methods in the right session.

		call_gate_method => sub {
			my ($stage, $method, @args) = @_[ARG0..$#_];
			return $stage->$method(@args);
		},

		call_gate_coderef => sub {
			my ($coderef, @args) = @_[ARG0..$#_];
			return $coderef->(@args);
		},

		# Catch dynamic events.

		_default => sub {
			my ($event, $args) = @_[ARG0, ARG1];

			return $event->deliver($args) if "$event" =~ /^PoeEvent(?:::|=)/;

			return if PoeSession->deliver($_[SENDER]->ID, $event, $args);

			# Unhandled event.
			# TODO - Anything special?
		},

		### Support POE::Wheel classes.

		# Deliver to wheels based on the wheel ID.  Different wheels pass
		# their IDs in different ARGn offsets, so we need a few of these.
		wheel_event_0 => sub {
			$_[CALLER_FILE] =~ m{/([^/.]+)\.pm};
			"Wheel$1"->_deliver(0, @_[ARG0..$#_]);
		},
		wheel_event_1 => sub {
			$_[CALLER_FILE] =~ m{/([^/.]+)\.pm};
			"Wheel$1"->_deliver(1, @_[ARG0..$#_]);
		},
		wheel_event_2 => sub {
			$_[CALLER_FILE] =~ m{/([^/.]+)\.pm};
			"Wheel$1"->_deliver(2, @_[ARG0..$#_]);
		},
		wheel_event_3 => sub {
			$_[CALLER_FILE] =~ m{/([^/.]+)\.pm};
			"Wheel$1"->_deliver(3, @_[ARG0..$#_]);
		},
		wheel_event_4 => sub {
			$_[CALLER_FILE] =~ m{/([^/.]+)\.pm};
			"Wheel$1"->_deliver(4, @_[ARG0..$#_]);
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

has role => (
	isa     => 'Str',
	is      => 'ro',
);

has observers => (
	isa     => 'ArrayRef',
	is      => 'rw',
	default => sub { [] },
);

# Base class.

sub BUILD {
	my ($self, $args) = @_;

	foreach my $setup (
		(grep { $_->does('Emitter') } $self->meta()->get_all_attributes()),
		(grep { $_->does('Observer') } $self->meta()->get_all_attributes())
	) {
		my $callback = $setup->setup();
		if (defined $callback) {
			my $member = $setup->name();
			$self->$member( $callback->() ); # TODO - Proper parameters!
		}
	}

	foreach my $observer (@{$self->observers()}) {

		# Observing based on role.

		if (exists $observer->{role}) {
			my @required = qw(observer role);
			$self->_check_args(
				$observer,
				\@required,
				[ ],
			);

			my ($observer, $role) = @$observer{@required};

			$observer->observe_role(
				observed  => $self,
				role      => $role,
			);
			next;
		}

		# Observe without a role.

		my @required = qw(observer callback event);
		$self->_check_args(
			$observer,
			\@required,
			[ ],
		);

		my ($observer, $callback, $event) = @$observer{@required};

		$observer->observe(
			observed  => $self,
			event     => $event,
			callback  => $callback,
		);
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
	my ($self, @args) = @_;

	my @required = qw(observed event callback);
	my $args = $self->_check_args(
		\@args,
		\@required,
		[ ],
	);

	my ($observed, $event, $callback) = @$args{@required};

	# Register what I'm watching.

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

	$observed->is_observed($self, $event, $callback);

	undef;
}

# Self is no longer being observed.  Remove observations from self.
sub isnt_observed {
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

sub is_observed {
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

sub observe_role {
	my ($self, @args) = @_;

	my @required = qw(observed role);
	my $args = $self->_check_args(
		\@args,
		\@required,
		[ ],
	);

	my ($observed, $role) = @$args{@required};

	# Find all relevant methods in the obsever, and explicitly observe
	# the corresponding events.  Heavy at setup, but light while
	# running.

	foreach my $callback (
		grep /^on_${role}_\S+$/,
		map { $_->name }
		$self->meta()->get_all_methods()
	) {
		my ($event) = ($callback =~ /^on_${role}_(\S+)$/);

		$self->observe(
			observed  => $observed,
			event     => $1,
			callback  => $callback,
		);
	}

	undef;
}

sub emit {
	my ($self, @args) = @_;

	my $args = $self->_check_args(
		\@args,
		[ 'event' ],
		[ 'args' ],
	);

	my $event         = $args->{event};
	my $callback_args = $args->{args} || {};

	# Look for self-handling of the event.

	if ($self->can("on_my_$event")) {
		my $method = "on_my_$event";
		$self->$method($callback_args);
		return;
	}

	# This event isn't observed.

	return unless (
		exists $self->watchers_by_event()->{$event}
	);

	# This event is observed.  Broadcast it to observers.

	while (
		my ($observer, $callbacks) = each %{$self->watchers_by_event()->{$event}}
	) {
		CALLBACK: foreach my $callback_rec (@$callbacks) {
			my $callback = $callback_rec->{callback};

			# Coderef callback.

			if (ref($callback) eq 'CODE') {
				# Same session.  Just call it.
				if (
					$callback_rec->{observer}->session_id() eq
					$POE::Kernel::poe_kernel->get_active_session()->ID
				) {
					$callback->($callback_args);
					next CALLBACK;
				}

				# Different session.  Post it through.
				# TODO - Multisession is not tested yet.
				$poe_kernel->post(
					$callback_rec->{observer}->session_id(), 'emit_to_coderef',
					$callback, $callback_args,
					$callback_rec->{observer}, $self, # keep objects alive a bit
				);
				next CALLBACK;
			}

			# Method callback.

			if (
					$callback_rec->{observer}->session_id() eq
					$POE::Kernel::poe_kernel->get_active_session()->ID
			) {
				# Same session.  Just call it.
				$callback_rec->{observer}->$callback($callback_args);
			}
			else {
				# Different session.  Post it through.
				# TODO - Multisession is not tested yet.
				$poe_kernel->post(
					$callback_rec->{observer}->session_id(), 'emit_to_method',
					$callback_rec->{observer}, $callback, $callback_args,
					$self, # keep object alive a bit
				);
			}
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

sub shutdown {
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
	$self->shutdown();
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
		$observed->isnt_observed($self, \@events);
	}
	else {
		delete $self->watched_object_events()->{$observed};
		delete $self->watched_objects()->{$observed};
		$observed->isnt_observed($self);

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

no Moose;
#__PACKAGE__->meta()->make_immutable();

1;
