package Proxy;
use Moose;
extends 'Reflex::Object';

has handle_a => ( is => 'rw', isa => 'FileHandle', required => 1 );
has handle_b => ( is => 'rw', isa => 'FileHandle', required => 1 );

with 'Streamable' => { handle => 'handle_a' };
with 'Streamable' => { handle => 'handle_b' };

# TODO - put() methods.

1;
