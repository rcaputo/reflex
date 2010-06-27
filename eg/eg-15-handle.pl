#!/usr/bin/env perl

use lib qw(../lib);

{
	package UdpPeer;

	use Moose;
	extends 'Reflex::Base';
	use Reflex::Handle;

	has port => (
		isa => 'Int',
		is  => 'ro',
	);

	has handle => (
		isa     => 'Reflex::Handle|Undef',
		is      => 'rw',
		traits  => ['Reflex::Trait::Observed'],
		role    => 'remote',
	);

	after 'BUILD' => sub {
		my $self = shift;

		$self->handle(
			Reflex::Handle->new(
				handle => IO::Socket::INET->new(
					Proto     => 'udp',
					LocalPort => $self->port(),
				),
				rd => 1,
			)
		);
		undef;
	};

	sub on_remote_readable {
		my ($self, $args) = @_;

		my $remote_address = recv(
			$args->{handle},
			my $datagram = "",
			16384,
			0
		);

		if ($datagram =~ /^\s*quit\s*$/i) {
			$self->handle(undef);
			return;
		}

		return if send(
			$args->{handle},
			$datagram,
			0,
			$remote_address,
		) == length($datagram);
	}
}

my $port = 12345;
print "Starting UDP echo service on port $port.\n";
exit UdpPeer->new( port => $port )->run_all();
