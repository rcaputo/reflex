#!/usr/bin/env perl

use warnings;
use strict;
use lib qw(../lib);

# An object's emitted events can also trigger methods in the subclass.
# This example is a direct port of eg-04-inheritance.pl, but it uses a
# Reflex::UdpPeer object rather than inheriting from that class.

{
	package Reflex::Udp::Echo;
	use Moose;
	extends 'Reflex::Base';
	use Reflex::UdpPeer;
	use Reflex::Trait::Observed qw(observes);

	has port => (
		isa     => 'Int',
		is      => 'ro',
	);

	observes peer => (
		isa     => 'Maybe[Reflex::UdpPeer]',
		setup   => sub {
			my $self = shift;
			Reflex::UdpPeer->new(
				socket => IO::Socket::INET->new(
					LocalPort => $self->port(),
					Proto     => 'udp',
				)
			)
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
my $peer = Reflex::Udp::Echo->new( port => $port );
print "UDP echo service is listening on port $port.\n";
Reflex->run_all();
exit;
