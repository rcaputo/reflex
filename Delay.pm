package Delay;

use Moose;
extends qw(Stage);
use Scalar::Util qw(weaken);

has interval => (
	isa => 'Num',
	is => 'rw',
);

has alarm_id => (
	isa => 'Str|Undef',
	is => 'rw',
);

has auto_repeat => (
	isa => 'Bool',
	is => 'rw',
);

sub BUILD {
	my $self = shift;
	$self->repeat();
}

sub repeat {
	my $self = shift;

	return unless defined $self->interval() and $self->call_gate("repeat");

	# Stop a previous alarm?

	$self->stop() if defined $self->alarm_id();

	# Put a weak $self in an envelope that can be passed around.

	my $envelope = [ $self ];
	weaken $envelope->[0];

	$self->alarm_id(
		$POE::Kernel::poe_kernel->delay_set(
			'timer_due',
			$self->interval(),
			$envelope,
		)
	);
}

sub _deliver {
	my $self = shift;
	$self->alarm_id(0);
	$self->emit( event => "tick" );
	$self->repeat() if $self->auto_repeat();
}

sub DEMOLISH {
	my $self = shift;
	$self->stop();
}

sub stop {
	my $self = shift;

	return unless defined $self->alarm_id() and $self->call_gate("stop");

	$POE::Kernel::poe_kernel->alarm_remove($self->alarm_id());
	$self->alarm_id(undef);
}

no Moose;
__PACKAGE__->meta()->make_immutable();

1;
