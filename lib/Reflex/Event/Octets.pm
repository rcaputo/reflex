package Reflex::Event::Octets;

use Moose;
extends 'Reflex::Event';

has octets => (
	is       => 'ro',
	isa      => 'Str',
	required => 1,
);

__PACKAGE__->meta->make_immutable;

1;
