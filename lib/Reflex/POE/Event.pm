package Reflex::POE::Event;

use Moose;
use Carp qw(croak);

has object => (
	is => 'ro',
	isa => 'Reflex::Object',
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
		$self->object()->session_id()
	) {
		croak(
			"When interfacing with POE at large, ", __PACKAGE__, " must\n",
			"be created within a Reflex::Object's session.  Perhaps invoke it\n",
			"within the object's run_within_session() method",
		);
	}
}

sub deliver {
	my ($self, $args) = @_;

	$POE::Kernel::poe_kernel->post(
		$self->object()->session_id(), "call_gate_method",
		$self->object(), $self->method(), {
			context   => $self->context(),
			response  => [ @$args ],
		}
	);
}

1;
