# A UDP peer.

package UdpPeer;
use Moose;
with 'UdpPeerRole';

# Composes the UdpPeerRole role into a class.
# Does nothing of its own.

no Moose;
__PACKAGE__->meta()->make_immutable();

1;
