package Reflex::Event::Postback;

use Moose;
extends 'Reflex::Event';

has context => (
	is       => 'ro',
	isa      => 'HashRef[Any]',
	required => 1,
);

has response => (
	is       => 'ro',
	isa      => 'ArrayRef[Any]',
	required => 1,
);

1;
