package Reflex::Wakeup;

use Moose;
extends 'Reflex::Base';

has when => ( isa => 'Num', is  => 'rw' );

with 'Reflex::Role::Wakeup' => {
	when          => "when",
	cb_wakeup     => "on_time",
	method_stop   => "stop",
	method_reset  => "reset",
};

1;
