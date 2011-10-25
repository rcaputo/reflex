package Reflex::Event::SigChild;

use Moose;
extends 'Reflex::Event::Signal';

has pid => (
	is       => 'ro',
	isa      => 'Int',
	required => 1,
);

has exit => (
	is       => 'ro',
	isa      => 'Int',
	required => 1,
);

1;
