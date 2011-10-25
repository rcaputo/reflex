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

1;
