# A UDP peer.

package Reflex::UdpPeer;
use Moose;
with 'Reflex::Role::UdpPeer';

# Composes Reflex::Role::udpPeer into a class.
# Does nothing of its own.

no Moose;
__PACKAGE__->meta()->make_immutable();

1;
