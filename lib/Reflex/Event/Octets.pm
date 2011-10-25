package Reflex::Event::Octets;

use Moose;
extends 'Reflex::Event';

has octets => (
	is       => 'ro',
	isa      => 'Str',
	required => 1,
);

1;
