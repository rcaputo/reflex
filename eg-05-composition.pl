#!/usr/bin/env perl

# An object's emitted events can also trigger methods in the subclass.
# This example is a direct port of eg-04-inheritance.pl, but it uses a
# UdpPeer object rather than inheriting from the UdpPeer class.

{
	package UdpEchoPeer;
	use Moose;
	extends 'Stage';
	use UdpPeer;

	has peer => (
		isa => 'UdpPeer|Undef',
		is  => 'rw',
	);

	sub BUILD {
		my ($self, $args) = @_;
		$self->peer(
			UdpPeer->new(
				port => $args->{port},
				observers => [
					{
						observer => $self,
						role     => 'peer',
					}
				]
			)
		);
	}

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

my $port = 12345;
my $peer = UdpEchoPeer->new( port => $port );
print "UDP echo service is listening on port $port.\n";
POE::Kernel->run();
exit;
