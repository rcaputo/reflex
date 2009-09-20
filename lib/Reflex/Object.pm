package Reflex::Object;

use Moose;
with 'Reflex::Role::Object';

# Composes the Reflex::Role::Object into a class.
# Does nothing of its own.

no Moose;
__PACKAGE__->meta()->make_immutable();

1;
