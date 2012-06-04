package Reflex::Event::POE;

use Moose;
extends 'Reflex::Event';

has args => (
	is       => 'ro',
	isa      => 'ArrayRef[Any]',
	required => 1,
	traits   => [ 'Array' ],
	handles  => {
		args_list => 'elements',
	},
);

__PACKAGE__->make_event_cloner;
__PACKAGE__->meta->make_immutable;

1;
