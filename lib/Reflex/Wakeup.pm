package Reflex::Wakeup;

use Moose;
extends 'Reflex::Base';

has name        => ( isa => 'Str', is => 'ro', default => 'timeout' );
has when        => ( isa => 'Num', is  => 'rw' );

with 'Reflex::Role::Wakeup' => {
	name          => "name",
	when          => "when",
	cb_wakeup     => "on_time",
	method_stop   => "stop",
	method_reset  => "reset",
};

1;
