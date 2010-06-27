#!/usr/bin/env perl

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

	has socket => (
		is        => 'ro',
		isa       => 'FileHandle',
		required  => 1,
	);

	with 'Reflex::Role::Recving' => {
		handle => 'socket',

		# Expose send_socket() as send().
		-alias    => { send_socket => 'send' },
		-excludes => 'send_socket'
		
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
