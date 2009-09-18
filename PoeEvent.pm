package PoeEvent;

use Moose;
use Carp qw(croak);

has stage => (
	is => 'ro',
	isa => 'Stage',
);

has method => (
	is => 'rw',
	isa => 'Str',
);

has context => (
	is => 'rw',
	isa => 'HashRef',
);

sub BUILD {
	my $self = shift;

	if (
		$POE::Kernel::poe_kernel->get_active_session()->ID()
		ne
		$self->stage()->session_id()
	) {
		croak(
			"When interfacing with POE at large, ", __PACKAGE__, " must\n",
			"be created within a Stage's session.  Perhaps invoke it within\n",
			"the stage's run_within_session() method",
		);
	}
}

sub deliver {
	my ($self, $args) = @_;

	$POE::Kernel::poe_kernel->post(
		$self->stage()->session_id(), "call_gate_method",
		$self->stage(), $self->method(), {
			passthrough => $self->context(),
			callback    => [ @$args ],
		}
	);
}

1;
