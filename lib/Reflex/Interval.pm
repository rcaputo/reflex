package Reflex::Interval;

use Moose;
extends 'Reflex::Base';

has interval    => ( isa => 'Num', is  => 'ro' );
has auto_repeat => ( isa => 'Bool', is => 'ro', default => 1 );
has auto_start  => ( isa => 'Bool', is => 'ro', default => 1 );

with 'Reflex::Role::Interval' => {
	interval      => "interval",
	auto_start    => "auto_start",
	auto_repeat   => "auto_repeat",
	cb_tick       => "on_tick",
	method_start  => "start",
	method_stop   => "stop",
	method_repeat => "repeat",
};

1;
