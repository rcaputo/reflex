# A UDP peer.

package Reflex::UdpPeer;
use Moose;
with 'Reflex::Role::UdpPeer';

# Composes Reflex::Role::udpPeer into a class.
# Does nothing of its own.

no Moose;
__PACKAGE__->meta()->make_immutable();

1;

__END__

=head1 NAME

Reflex::UdpPeer - Base class for reactive UDP peers.

=head1 DESCRIPTION

Reflex::UdpPeer is a base class for reactive UDP peers.  It takes all
its functionality from Reflex::Role::UdpPeer, so please see that
module for documentation.

=head1 SEE ALSO

Reflex::Role::UdpPeer - Documents Reflex::UdpPeer.

=head1 BUGS

TODO - Link to RT.

=head1 AUTHORS

Rocco Caputo.

=head1 COPYRIGHT AND LICENSE

=cut
