# $Id$

# Base class for binary TTL gates.

package Ttl::Bin;
use Moose;
extends 'Stage';
use EmitterTrait;

has a => (
	isa     => 'Bool',
	is      => 'rw',
	traits  => ['Emitter'],
	event   => 'change',
);

has b => (
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
