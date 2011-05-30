#!/usr/bin/env perl
# vim: ts=2 sw=2 noexpandtab

use warnings;
use strict;
use lib qw(../lib);

# This example creates a UDP echo server using a role rather than
# inheritance.

{
	package Reflex::Udp::Echo;
	use Moose;
	extends 'Reflex::Base';
	use IO::Socket::INET;
	use Reflex::Callbacks qw(make_error_handler);

	has socket => (
		is        => 'ro',
		isa       => 'FileHandle',
		required  => 1,
	);

	has active => (
		is        => 'ro',
		isa       => 'Bool',
		default   => 1,
	);

	make_error_handler("on_socket_error");

	with 'Reflex::Role::Recving' => {
		att_handle  => 'socket',
		att_active  => 'active',
		method_send => 'send',
	};

	sub on_socket_datagram {
		my ($self, $arg) = @_;

		if ($arg->{datagram} =~ /^\s*shutdown\s*$/) {
			$self->stop_socket_readable();
			return;
		}

		$self->send(%$arg);
	}
}

# Main.

my $port = 12345;
my $peer = Reflex::Udp::Echo->new(
	socket => IO::Socket::INET->new(
		LocalPort => $port,
		Proto     => 'udp',
	)
);
print "UDP echo service is listening on port $port.\n";
Reflex->run_all();
exit;
