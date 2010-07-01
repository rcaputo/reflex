package Reflex::Role::Collectible;

# A Moose role that implements the Collectible side of the
# Collectible/Collection contract.  See Reflex::Collection.

use Moose::Role;

sub stopped {
	my $self = shift;
	$self->emit( event => "stopped", args => {} );
}

1;

__END__

=head1 NAME

Reflex::Role::Collectible - add manageability by Reflex::Collection

=head1 SYNOPSIS

	package Bauble;
	use Moose;
	with 'Reflex::Role::Collectible';

	sub stop {
		my $self = shift;
		$self->stopped();
	}

	1;

=head1 DESCRIPTION

Reflex::Role::Collectible allows consumers to be managed by
Reflex::Collection.  This role provides a stopped() method that causes
the Collectible object to be removed from any Collections that contain
it.

For example, a TCP server may use Reflex::Collection to manage a pool
of active Reflex::Stream objects, each representing a single client
connection.  Reflex::Stream calls stopped() by default whenever
sockets close or encounter errors, and the server dutifly deletes
them.

=head1 EXAMPLES

TODO - I'm sure there are some.

=head1 SEE ALSO

L<Reflex>
L<Reflex::Collection>
L<Reflex::Stream>

L<Reflex/ACKNOWLEDGEMENTS>
L<Reflex/ASSISTANCE>
L<Reflex/AUTHORS>
L<Reflex/BUGS>
L<Reflex/BUGS>
L<Reflex/CONTRIBUTORS>
L<Reflex/COPYRIGHT>
L<Reflex/LICENSE>
L<Reflex/TODO>

=cut
