# $Id$

# Base class for unary TTL gates.

package Ttl::Un;
use Moose;
extends 'Reflex::Object';
use Reflex::Trait::Emitter;

has in => (
	isa     => 'Bool',
	is      => 'rw',
	traits  => ['Reflex::Trait::Emitter'],
	event   => 'change',
);

has out => (
	isa     => 'Bool',
	is      => 'rw',
	traits  => ['Reflex::Trait::Emitter'],
);

1;
