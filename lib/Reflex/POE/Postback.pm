package Reflex::POE::Postback;

# TODO - Not Moose, unless Moose allows us to create blessed coderefs.

use warnings;
use strict;
use Scalar::Util qw(weaken);

my %owner_session_ids;

sub new {
	my ($class, $object, $method, $context) = @_;

	# TODO - Object owns component, which owns object?
	weaken $object;

	my $self = bless sub {
		$POE::Kernel::poe_kernel->post(
			$object->session_id(), "call_gate_method", $object, $method, {
				context   => $context,
				response  => [ @_ ],
			},
		);
	}, $class;

	$owner_session_ids{$self} = $object->session_id();
	$POE::Kernel::poe_kernel->refcount_increment(
		$object->session_id(), "reflex_postback"
	);

	# Double indirection sucks, but some libraries (like Tk) bless their
	# callbacks.  If we returned our own blessed callback, they would
	# alter the class and thwart DESTROY.
	#
	# TODO - POE::Session only does this when Tk is loaded.  I opted
	# against it here because the set of libraries that bless their
	# callbacks may grow over time.

	return sub { $self->(@_) };
}

sub DESTROY {
	my $self = shift;

	my $session_id = delete $owner_session_ids{$self};
	return unless defined $session_id;
	$POE::Kernel::poe_kernel->refcount_decrement(
		$session_id, "reflex_postback"
	);

	undef;
}

1;
# TODO - Document.

__END__

=head1 NAME

Reflex::POE::Postback - Communicate with POE components expecting postbacks.

=head1 SYNOPSIS

# Not a complete example.  Please see eg-11-poco-postback.pl in the
# examples for a working one.

	$self->component->request(
		Reflex::POE::Postback->new(
			$self, "on_component_result", { cookie => 123 }
		),
	);

TODO - Needs a better example.

=head1 DESCRIPTION

Reflex::POE::Postback creates an object that's compatible with the POE
postback.  These may be given to POE components that require postbacks to
work.

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
