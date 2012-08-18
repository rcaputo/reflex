package EventBench::Reflex::Event; 

use Moose;
use Reflex;

extends 'Reflex::Event'; 

has arg1 => ( is => 'ro', isa => 'Num', required => 1 );
has arg2 => ( is => 'ro', isa => 'Num', required => 1 );

__PACKAGE__->meta->make_immutable; 

1; 
