package Reflex::Codec::Message::Stream;
# vim: ts=2 sw=2 noexpandtab

use Moose;
extends 'Reflex::Codec::Message';

has '+is_combinable' => ( default => 1 );

has octets  => (
	is        => 'rw',
	isa       => 'Str',
	default   => '',
	traits    => [ 'String' ],
	handles   => {
		append  => 'append',
		match => 'match',
		substr => 'substr',
		length => 'length',
	},
);

__PACKAGE__->meta->make_immutable;

1;
