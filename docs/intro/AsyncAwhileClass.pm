package AsyncAwhileClass;
use Moose;
extends 'Reflex::Base';

has name    => ( is => 'ro', isa => 'Str', default => 'awhile' );
has awhile  => ( is => 'ro', isa => 'Int', default => 1 );

with 'AsyncAwhileRole' => { cb => 'on_done' };

1;
