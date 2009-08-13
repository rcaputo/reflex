#!/usr/bin/env perl

# An object's emitted events can also trigger methods in the subclass.
# This example creates a UDP echo server using a role rather than
# inheritance.

{
	package UdpEchoPeer;
	use Moose;
	with 'UdpPeerRole';

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

my $port = 12345;
my $peer = UdpEchoPeer->new( port => $port );
print "UDP echo service is listening on port $port.\n";
POE::Kernel->run();
exit;
