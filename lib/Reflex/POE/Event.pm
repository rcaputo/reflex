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

__END__

=head1 NAME

Reflex::POE::Event - Communicate with POE components expecting events.

=head1 SYNOPSIS

# Not a complete example.  Please see eg-12-poco-event.pl in the
# examples for a working one.

	$self->run_within_session(
		sub {
			$self->component->request(
				Reflex::POE::Event->new(
					object  => $self,
					method  => "on_component_result",
					context => { cookie => 123 },
				),
			);
		}
	);

TODO - Needs a better example.

=head1 DESCRIPTION

Reflex::POE::Event creates an object that may be used as a POE event.
When this event is posted back to Reflex, it will be routed to the
proper Reflex::Object and method.

Reflex will clean up its bookkeeping for this event when the object is
destroyed.  It's therefore important to maintain the object's blessing
until it's definitely through being used.

TODO - Is there a better, more reliable way to track the end of an
event's use?

TODO - Complete the documentation.

=head1 GETTING HELP

L<Reflex/GETTING HELP>

=head1 ACKNOWLEDGEMENTS

L<Reflex/ACKNOWLEDGEMENTS>

=head1 SEE ALSO

L<Reflex> and L<Reflex/SEE ALSO>

=head1 BUGS

L<Reflex/BUGS>

=head1 CORE AUTHORS

L<Reflex/CORE AUTHORS>

=head1 OTHER CONTRIBUTORS

L<Reflex/OTHER CONTRIBUTORS>

=head1 COPYRIGHT AND LICENSE

L<Reflex/COPYRIGHT AND LICENSE>

=cut
