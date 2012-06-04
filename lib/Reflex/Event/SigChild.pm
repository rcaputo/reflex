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

__PACKAGE__->make_event_cloner;
__PACKAGE__->meta->make_immutable;

1;
