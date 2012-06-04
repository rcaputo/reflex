package Reflex::Event::Datagram;

use Moose;
extends 'Reflex::Event::Octets';

# TODO - Extend Moose's type hierarchy to support Internet addresses?

# TODO - Lazy attributes for the peer address and port parts of the
# peer name.

# TODO - Move the peer name into a role, in case other kinds of events
# want to include them?  YDNI yet.  I think they would just inherit
# from this class?

has peer => (
	is       => 'ro',
	isa      => 'Str',
	required => 1,
);

__PACKAGE__->make_event_cloner;
__PACKAGE__->meta->make_immutable;

1;
