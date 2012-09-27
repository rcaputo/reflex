package HttpResponseEvent;

use Moose;
extends 'Reflex::Event';

use HTTP::Request;
use HTTP::Response;

has request => (
	is       => 'ro',
	isa      => 'HTTP::Request',
	required => 1,
);

has response => (
	is       => 'ro',
	isa      => 'HTTP::Response',
	required => 1,
);

__PACKAGE__->make_event_cloner;
__PACKAGE__->meta->make_immutable;

1;
