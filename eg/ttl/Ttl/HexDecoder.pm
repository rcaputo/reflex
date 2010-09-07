# Four-input binary to hexadecimal digit decoder.
# Cheats by not simulating all the inner circuitry.

package Ttl::HexDecoder;
use Moose;
extends 'Reflex::Base';

use Reflex::Trait::EmitsOnChange;

emits ones   => ( isa => 'Bool', event => 'change' );
emits twos   => ( isa => 'Bool', event => 'change' );
emits fours  => ( isa => 'Bool', event => 'change' );
emits eights => ( isa => 'Bool', event => 'change' );
emits out    => ( isa => 'Str'                     );

sub on_my_change {
	my $self = shift;

	my $decimal = (
    ($self->ones()   || 0) * 1 +
    ($self->twos()   || 0) * 2 +
    ($self->fours()  || 0) * 4 +
    ($self->eights() || 0) * 8
	);

  $self->out( ("0".."9","a".."f")[$decimal] );
}

1;
