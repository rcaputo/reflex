package Stage;

use Moose;

use Scalar::Util qw(weaken blessed);
use Carp qw(croak);

# TODO - I would like %watchers and %observed to be part of each
# object, but this is currently beyond my Moose skills.

my %observers;
my %observations;

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

my $singleton_session_id = POE::Session->create(
	inline_states => {
		# Make the session conveniently accessible.
		# Although we're using the $singleton_session_id, so why bother?

		_start => sub {
			# Stayin' alive!
			$_[KERNEL]->refcount_increment($_[SESSION]->ID, "beegees");
		},

		shutdown => sub {
			$_[KERNEL]->refcount_decrement($_[SESSION]->ID, "beegees");
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

has observers => (
	isa     => 'ArrayRef',
	is      => 'rw',
	default => sub { [] },
);

has role => (
	isa     => 'Str',
	is      => 'ro',
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
}

# TODO - Does Moose have sugar for passing named parameters?

sub observe {
	my ($self, @args) = @_;

	my @required = qw(observed event callback);
	my $args = $self->_check_args(
		\@args,
		\@required,
		[ ],
	);

	my ($observed, $event, $callback) = @$args{@required};

	# TODO - Callback magic?

	push @{$observers{$self}{$observed}}, {
		event    => $event,
		callback => $callback,
	};

	my %observation = (
		observer  => $self,
		observed  => $observed,
		event     => $event,
		callback  => $callback,
	);
	weaken $observation{observer};

	push @{$observations{$observed}{$event}{$self}}, \%observation;

	undef;
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

	# This object isn't observed.
	return unless exists $observations{$self};

	while (my ($observer, $observations) = each %{$observations{$self}{$event}}) {
		foreach my $observation (@$observations) {
			my $callback = $observation->{callback};

			if (ref($callback) eq 'CODE') {
				$poe_kernel->post(
					$self->session_id(),
					emit_to_coderef => $callback, $callback_args,
					$observation->{observer}, $observation->{observed},
				);
			}
			else {
				if ($observation->{observer}->session_id() == $self->session_id()) {
					# Same session.  Just call it.
					$observation->{observer}->$callback($callback_args);
				}
				else {
					# Different session.  Post it through.
					$poe_kernel->post(
						$self->session_id(), 'emit_to_method',
						 $observation->{observer}, $callback, $callback_args,
					);
				}
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

	# Find ever observed object, and the list of events observed.
	# Clean them all out.
	# Automortify would rock.
	while (my ($observed, $observations) = each %{$observers{$self}}) {
		foreach my $event ( map { $_->{event} } @$observations ) {
			delete $observations{$observed}{$event}{$self};
			unless (scalar keys %{$observations{$observed}{$event}}) {
				delete $observations{$observed}{$event};
				unless (scalar keys %{$observations{$observed}}) {
					delete $observations{$observed};
				}
			}
		}
	}

	delete $observers{$self};
	undef;
}

sub ignore {
	my ($self, @args) = @_;

	my $args = $self->_check_args(
		\@args,
		[ 'observed' ],
		[ 'events' ],
	);

	my $observed  = $args->{observed};

	# Not actually observing it.
	return unless (
		exists $observers{$self} and
		exists $observers{$self}{$observed}
	);

	my @events = @{$args->{events} || []};
	if (@events) {
		# Clean out the explicit events.
		# TODO - Untested.
		my $i = @{$observers{$self}{$observed}};
		my %events = map { $_ => 1 } @events;
		while ($i--) {
			next unless exists $events{$observers{$self}{$observed}{event}};
			splice @{$observers{$self}{$observed}}, $i, 1;
		}

		delete $observers{$self}{$observed} unless @{$observers{$self}{$observed}};
	}
	else {
		# Ignoring all events.
		@events = (
			map { $_->{event} }
			@{$observers{$self}{$observed}}
		);

		# Quickly clean out the observer.
		delete $observers{$self}{$observed};
	}

	delete $observers{$self} unless scalar keys %{$observers{$self}};

	# Clean out specific observations.
	if (exists $observations{$observed}) {
		foreach my $event (@events) {
			next unless exists $observations{$observed}{$event};
			delete $observations{$observed}{$event}{$self};

			# Automortification would rock.
			next if scalar keys %{$observations{$observed}{$event}};
			delete $observations{$observed}{$event};
			next if scalar keys %{$observations{$observed}};
			delete $observations{$observed};
		}
	}

	# Mortify the whole observer, if needed.
	delete $observers{$self} unless scalar keys %{$observers{$self}};

	# No more objects for this session?  Time to shut down this session.
	unless (scalar keys %observers) {
		$POE::Kernel::poe_kernel->call($self->session_id(), "shutdown");
	}
}

1;
