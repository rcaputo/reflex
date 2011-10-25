package Reflex::Event::FileHandle;

use Moose;
extends 'Reflex::Event';

has handle => (
	is       => 'ro',
	isa      => 'FileHandle',
	required => 1,
);

1;
