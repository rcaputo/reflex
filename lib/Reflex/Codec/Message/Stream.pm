package Reflex::Codec::Message::Stream;

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

1;
