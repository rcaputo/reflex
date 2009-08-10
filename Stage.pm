package Stage;

use Moose;

use Scalar::Util qw(weaken blessed);
use Carp qw(croak);

# TODO - I would like %observers and %observed to be part of each
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
			$_[KERNEL]->alias_set(__PACKAGE__);
		},

		# Handle a timer.  Deliver it to its resource.
		# $resource is an envelope around a weak POE::Watcher reference.

		set_timer => sub {
			my ($kernel, $interval, $object) = @_[KERNEL, ARG0, ARG1];

			# Weaken the object so it may destruct while there's a timer.
			my $envelope = [ $object ];
			weaken $envelope->[0];

			return $kernel->delay_set(
				'timer',
				$interval,
				$envelope,
			);
		},

		clear_timer => sub {
			my ($kernel, $timer_id) = @_[KERNEL, ARG0];
			$kernel->alarm_remove($timer_id);
		},

		timer => sub {
			my $resource = $_[ARG0];
			eval { $resource->[0]->_deliver(); };
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

		_stop => sub { undef },
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

	# This object isn't observed.
	return unless exists $observations{$self};

	my $args = $self->_check_args(
		\@args,
		[ 'event' ],
		[ 'args' ],
	);

	my $event         = $args->{event};
	my $callback_args = $args->{args} || {};

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
				$poe_kernel->post(
					$self->session_id(),
					emit_to_method => $observation->{observer}, $callback, $callback_args,
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

1;
