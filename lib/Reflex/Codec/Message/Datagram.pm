package Reflex::Codec::Message::Datagram;

use Moose;
extends 'Reflex::Codec::Message';

has octets  => (
	is        => 'rw',
	isa       => 'Str',
	default   => '',
);

1;
