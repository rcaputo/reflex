#!/usr/bin/env perl

use warnings;
use strict;

use ZeroMQ::Raw::Constants qw(ZMQ_SUB ZMQ_SUBSCRIBE);

use ZmqSocket;

my $s = ZmqSocket->new(
	socket_type => ZMQ_SUB,
	endpoints   => [ 'tcp://127.0.0.1:12345' ],
#	setsockopt  => [
#		[ ZMQ_SUBSCRIBE, 'debug:' ],
#	],
);

while (my $msg = $s->next()) {
	# TODO - I don't like this, but what's better?
	warn $msg->{arg}->{msg}->data();
}
