package Reflex::Event::FileHandle;

use Moose;
extends 'Reflex::Event';

has handle => (
	is       => 'ro',
	isa      => 'FileHandle',
	required => 1,
);

__PACKAGE__->meta->make_immutable();

1;
