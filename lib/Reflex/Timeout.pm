package Reflex::Timeout;

use Moose;
extends 'Reflex::Base';

has name        => ( isa => 'Str', is => 'ro', default => 'timeout' );
has delay       => ( isa => 'Num', is  => 'ro' );

# TODO - There is a flaw in the design.
#
# Reflex::Timeout = cb_timeout => "on_done"
# Reflex::Role::Timeout = method_emit $cb_timeout => "done"
#
# However, the user's on_done => callback() only works because the
# emitted event is "done".  And this "done" is a constant, which means
# we pretty much have to use "on_done" here, or the chain of events is
# broken.
#
# Somehow we must make the chain of events work no matter what
# cb_timeout is set to here.

with 'Reflex::Role::Timeout' => {
	name          => "name",
	delay         => "delay",
	cb_timeout    => "on_done",
	method_start  => "start",
	method_stop   => "stop",
	method_reset  => "reset",
};

1;
