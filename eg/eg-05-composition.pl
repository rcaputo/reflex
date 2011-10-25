#!/usr/bin/env perl
# vim: ts=2 sw=2 noexpandtab

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
	use Reflex::Trait::Watched qw(watches);

	has port => (
		isa     => 'Int',
		is      => 'ro',
	);

	watches peer => (
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
		my ($self, $datagram) = @_;

		my $octets = $datagram->octets();

		if ($octets =~ /^\s*shutdown\s*$/) {
			$self->peer(undef);
			return;
		}

		$self->peer()->send(
			octets => $octets,
			peer   => $datagram->peer(),
		);
	}

	sub on_peer_error {
		my ($self, $error) = @_;
		warn(
			$error->function(),
			" error ", $error->number(),
			": ", $error->string(),
		);
		$self->peer(undef);
	}
}

# Main.

my $port = 12345;
my $peer = Reflex::Udp::Echo->new( port => $port );
print "UDP echo service is listening on port $port.\n";
Reflex->run_all();
exit;
