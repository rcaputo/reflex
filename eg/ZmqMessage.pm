package ZmqMessage;

use Moose;
extends 'Reflex::Event';

has message => (
	is       => 'ro',
	isa      => 'ZeroMQ::Raw::Message',
	required => 1,
);

1;
