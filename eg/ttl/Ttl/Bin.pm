# $Id$

# Base class for binary TTL gates.

package Ttl::Bin;
use Moose;
extends 'Reflex::Base';

use Reflex::Trait::EmitsOnChange;

emits a   => ( isa => 'Bool', event => 'change' );
emits b   => ( isa => 'Bool', event => 'change' );
emits out => ( isa => 'Bool' );

1;
