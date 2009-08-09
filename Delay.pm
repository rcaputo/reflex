package Delay;

use Moose;
use Scalar::Util qw(weaken);
use Stage;
extends qw(Stage);

has interval => (
	isa => 'Num',
	is => 'rw',
);

has alarm_id => (
	isa => 'Str',
	is => 'rw',
);

has data => (
	isa => 'HashRef',
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

	$self->alarm_id(
		$POE::Kernel::poe_kernel->call(
			$self->session_id(),
			'set_timer',
			$self->interval(),
			$self
		)
	);
}

sub _deliver {
	my $self = shift;
	$self->alarm_id(0);
	$self->emit( event => "ding" );
	$self->repeat() if $self->auto_repeat();
}

sub DEMOLISH {
	my $self = shift;
	if ($self->alarm_id()) {
		$POE::Kernel::poe_kernel->call(
			$self->session_id(),
			'clear_timer',
			$self->alarm_id(),
		);
	}
}

1;
