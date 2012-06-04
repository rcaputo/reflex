package Reflex::Event::ValueChange;

use Moose;
extends 'Reflex::Event';

has old_value => (
	is       => 'ro',
	isa      => 'Any',
	required => 1,
);

has new_value => (
	is       => 'ro',
	isa      => 'Any',
	required => 1,
);

__PACKAGE__->make_event_cloner;
__PACKAGE__->meta->make_immutable;

1;
