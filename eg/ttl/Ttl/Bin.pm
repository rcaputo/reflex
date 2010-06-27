# $Id$

# Base class for binary TTL gates.

package Ttl::Bin;
use Moose;
extends 'Reflex::Base';
use Reflex::Trait::EmitsOnChange;

has a => (
	isa     => 'Bool',
	is      => 'rw',
	traits  => ['Reflex::Trait::EmitsOnChange'],
	event   => 'change',
);

has b => (
	isa     => 'Bool',
	is      => 'rw',
	traits  => ['Reflex::Trait::EmitsOnChange'],
	event   => 'change',
);

has out => (
	isa     => 'Bool',
	is      => 'rw',
	traits  => ['Reflex::Trait::EmitsOnChange'],
);

1;
