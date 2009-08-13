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

sub POE::Kernel::ASSERT_DEFAULT () { 1 }
use POE;

# Disable a warning.
POE::Kernel->run();

my %session_object_count;

my $singleton_session_id = POE::Session->create(
	inline_states => {
		# Make the session conveniently accessible.
		# Although we're using the $singleton_session_id, so why bother?

		_start => sub {
			# No-op.
		},

		# Handle a timer.  Deliver it to its resource.
		# $resource is an envelope around a weak POE::Watcher reference.

		timer_set => sub {
			my ($kernel, $interval, $object) = @_[KERNEL, ARG0, ARG1];

			# Weaken the object so it may destruct while there's a timer.
			my $envelope = [ $object ];
			weaken $envelope->[0];

			return $kernel->delay_set(
				'timer_due',
				$interval,
				$envelope,
			);
		},

		timer_clear => sub {
			my ($kernel, $timer_id) = @_[KERNEL, ARG0];
			$kernel->alarm_remove($timer_id);
		},

		timer_due => sub {
			my $envelope = $_[ARG0];
			eval { $envelope->[0]->_deliver(); };
			die if $@;
		},

		select_on => sub {
			my ($kernel, $object, @selects) = @_[KERNEL, ARG0..$#_];

			my $envelope = [ $object ];
			weaken $envelope->[0];

			foreach my $select (@selects) {
				my ($mode, $handle) = @$select;
				my $method = "select_$mode";
				$kernel->$method($handle, 'select_ready', $envelope, $mode);
			}
		},

		select_off => sub {
			my ($kernel, @selects) = @_[KERNEL, ARG0..$#_];

			foreach my $select (@selects) {
				my ($mode, $handle) = @$select;
				my $method = "select_$mode";
				$kernel->$method($handle, undef);
			}
		},

		select_ready => sub {
			my ($handle, $envelope, $mode) = @_[ARG0, ARG2, ARG3];
			eval { $envelope->[0]->_deliver($handle, $mode) };
			die if $@;
		},

		select_read_ready => sub {
			my $envelope = $_[ARG2];
			eval { $envelope->[0]->_deliver("read") };
			die if $@;
		},

		select_read_ready => sub {
			my $envelope = $_[ARG2];
			eval { $envelope->[0]->_deliver("read") };
			die if $@;
		},

		emit_to_coderef => sub {
			my ($callback, $args) = @_[ARG0, ARG1];
			$callback->($args);
		},

		emit_to_method => sub {
			my ($observer, $method, $args) = @_[ARG0..ARG2];
			$observer->$method($args);
		},

		_stop => sub {
			#warn "stage session stopped";
			undef;
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
	# TODO - Moose probably has a better way.
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
				if ($callback_rec->{observer}->session_id() == $self->session_id()) {
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

			if ($callback_rec->{observer}->session_id() == $self->session_id()) {
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

sub DEMOLISH {
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

1;
