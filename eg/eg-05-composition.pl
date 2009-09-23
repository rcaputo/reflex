#!/usr/bin/env perl

use warnings;
use strict;
use lib qw(lib);

# An object's emitted events can also trigger methods in the subclass.
# This example is a direct port of eg-04-inheritance.pl, but it uses a
# Reflex::UdpPeer object rather than inheriting from that class.

{
	package Reflex::UdpPeer::Echo;
	use Moose;
	extends 'Reflex::Object';
	use Reflex::UdpPeer;

	has port => (
		isa     => 'Int',
		is      => 'ro',
	);

	has peer => (
		isa     => 'Reflex::UdpPeer|Undef',
		is      => 'rw',
		traits  => ['Reflex::Trait::Observer'],
		setup   => sub {
			my $self = shift;
			Reflex::UdpPeer->new(port => $self->port());
		},
	);

	sub on_peer_datagram {
		my ($self, $args) = @_;
		my $data = $args->{datagram};

		if ($data =~ /^\s*shutdown\s*$/) {
			$self->peer(undef);
			return;
		}

		$self->peer()->send(
			datagram    => $data,
			remote_addr => $args->{remote_addr},
		);
	}

	sub on_peer_error {
		my ($self, $args) = @_;
		warn "$args->{op} error $args->{errnum}: $args->{errstr}";
		$self->peer(undef);
	}
}

# Main.

my $port = 12345;
my $peer = Reflex::UdpPeer::Echo->new( port => $port );
print "UDP echo service is listening on port $port.\n";
Reflex::Object->run_all();
exit;
