#!/usr/bin/env perl

use warnings;
use strict;

use ZmqSocket;
use ZeroMQ::Raw::Constants qw(ZMQ_PUB);

my $s = ZmqSocket->new(
	socket_type => ZMQ_PUB,
	endpoints => [ 'tcp://127.0.0.1:12345' ],
);

my $i = 0;
while (1) {
	my $scalar = "debug: message " . ++$i;
	print "$scalar = ", $s->send_scalar($scalar), "\n";
	sleep 1;
}
