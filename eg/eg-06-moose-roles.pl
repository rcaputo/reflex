#!/usr/bin/env perl

use warnings;
use strict;
use lib qw(../lib);

# An object's emitted events can also trigger methods in the subclass.
# This example creates a UDP echo server using a role rather than
# inheritance.

{
	package Reflex::UdpPeer::Echo;
	use Moose;
	extends 'Reflex::Object';
	with 'Reflex::Role::UdpPeer';

	sub on_my_datagram {
		my ($self, $args) = @_;
		my $data = $args->{datagram};

		if ($data =~ /^\s*shutdown\s*$/) {
			$self->destruct();
			return;
		}

		$self->send(
			datagram    => $data,
			remote_addr => $args->{remote_addr},
		);
	}

	sub on_my_error {
		my ($self, $args) = @_;
		warn "$args->{op} error $args->{errnum}: $args->{errstr}";
		$self->destruct();
	}
}

# Main.

my $port = 12345;
my $peer = Reflex::UdpPeer::Echo->new( port => $port );
print "UDP echo service is listening on port $port.\n";
Reflex::Object->run_all();
exit;
