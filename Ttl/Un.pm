# $Id$

# Base class for unary TTL gates.

package Ttl::Un;
use Moose;
extends 'Stage';
use EmitterTrait;

has in => (
	isa     => 'Bool',
	is      => 'rw',
	traits  => ['Emitter'],
	event   => 'change',
);

has out => (
	isa     => 'Bool',
	is      => 'rw',
	traits  => ['Emitter'],
);

1;
