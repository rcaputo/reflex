# $Id$

# Base class for unary TTL gates.

package Ttl::Un;
use Moose;
extends 'Reflex::Base';
use Reflex::Trait::EmitsOnChange;

has in => (
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
