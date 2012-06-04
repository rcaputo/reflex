package Reflex::Event::Signal;

use Moose;
extends 'Reflex::Event';

has signal => (
	is       => 'ro',
	isa      => 'Str',
	required => 1,
);

__PACKAGE__->make_event_cloner;
__PACKAGE__->meta->make_immutable;

1;
