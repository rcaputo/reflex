package Reflex::Event::Timeout;

use Moose;
extends 'Reflex::Event::Time';

__PACKAGE__->make_event_cloner;
__PACKAGE__->meta->make_immutable;

1;
