# vim: ts=2 sw=2 noexpandtab

# Base class for unary TTL gates.

package Ttl::Un;
use Moose;
extends 'Reflex::Base';
use Reflex::Trait::EmitsOnChange;

emits in  => ( isa => 'Bool', event => 'change' );
emits out => ( isa => 'Bool'                    );

1;
