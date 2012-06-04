package Reflex::Codec::Message::Datagram;
# vim: ts=2 sw=2 noexpandtab

use Moose;
extends 'Reflex::Codec::Message';

has octets  => (
	is        => 'rw',
	isa       => 'Str',
	default   => '',
);

__PACKAGE__->meta->make_immutable;

1;
