package Reflex::Role::Interval;
use Reflex::Role;
use Scalar::Util qw(weaken);

attribute_parameter interval    => "interval";
attribute_parameter auto_repeat => "auto_repeat";
attribute_parameter auto_start  => "auto_start";

method_parameter    method_stop   => qw( stop interval _ );
method_parameter    method_repeat => qw( repeat interval _ );
callback_parameter  cb_tick       => qw( on interval tick );

role {
	my $p = shift;

	my $interval      = $p->interval();
	my $timer_id_name = "${interval}_timer_id";
	my $method_repeat = $p->method_repeat();
	my $method_stop   = $p->method_stop();
	my $auto_start    = $p->auto_start();
	my $auto_repeat   = $p->auto_repeat();
	my $cb_tick       = $p->cb_tick();

	has $timer_id_name => (
		isa => 'Maybe[Str]',
		is  => 'rw',
	);

	# Work around a Moose edge case.
	sub BUILD {}

	after BUILD => sub {
		my ($self, $args) = @_;
		$self->$method_repeat() if $self->$auto_start();
	};

	method $method_repeat => sub {
		my ($self, $args) = @_;

		# Switch to the proper session.
		return unless (
			defined $self->$interval() and $self->call_gate($method_repeat)
		);

		# Stop a previous alarm.
		$self->$method_stop() if defined $self->$timer_id_name();

		# Put a weak $self in an envelope that can be passed around
		# without strenghtening the object.

		my $envelope = [ $self, $cb_tick ];
		weaken $envelope->[0];

		$self->$timer_id_name(
			$POE::Kernel::poe_kernel->delay_set(
				'timer_due',
				$self->$interval(),
				$envelope,
			)
		);
	};

	after DEMOLISH => sub {
		my ($self, $args) = @_;
		$self->$method_stop();
	};

	method $method_stop => sub {
		my ($self, $args) = @_;

		# Return if it was a false "alarm" (pun intended).
		return unless defined $self->$timer_id_name() and $self->call_gate("stop");

		$POE::Kernel::poe_kernel->alarm_remove($self->$timer_id_name());
		$self->$timer_id_name(undef);
	};

	method $cb_tick => sub {
		my ($self, $args) = @_;
		$self->emit(event => "tick", args => $args);
		$self->$method_repeat() if $self->$auto_repeat();
	};
};

1;

__END__

TODO - Document.
