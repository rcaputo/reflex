# $Id$

# Base class for binary TTL gates.

package Ttl::Bin;
use Moose;
extends 'Reflex::Object';
use Reflex::Trait::Emitter;

has a => (
	isa     => 'Bool',
	is      => 'rw',
	traits  => ['Reflex::Trait::Emitter'],
	event   => 'change',
);

has b => (
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
