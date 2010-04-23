package Reflex::UdpPeer;
use Moose;
extends 'Reflex::Object';
with 'Reflex::Role::UdpPeer';

# Composes Reflex::Role::udpPeer into a class.
# Does nothing of its own.

1;

__END__

=head1 NAME

Reflex::UdpPeer - Base class for non-blocking UDP networking peers.

=head1 SYNOPSIS

Inherit it.

	package Reflex::UdpPeer::Echo;
	use Moose;
	extends 'Reflex::UdpPeer';

	sub on_udppeer_datagram {
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

	sub on_udppeer_error {
		my ($self, $args) = @_;
		warn "$args->{op} error $args->{errnum}: $args->{errstr}";
		$self->destruct();
	}

Use it as a helper.

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

Compose objects with its base role.

	# See L<Reflex::Role::UdpPeer>.

Use it as a promise (like a condvar), or set callbacks in its
constructor.

	# TODO - Make an example.

=head1 DESCRIPTION

Reflex::UdpPeer is a base class for UDP network peers.  It waits for
datagrams on a socket, automatically receives them when they arrive,
and emits "datagram" events containing the data and senders'
addresses.  It also provides a send() method that handles errors.

However, all this is done by its implementation, which is over in
Reflex::Role::UdpPeer.  The documentation won't be repeated here, so
further details will be found with the role.  Code and docs together,
you know.

=head1 SEE ALSO

L<Moose::Manual::Concepts>

L<Reflex>
L<Reflex::Object>
L<Reflex::Role::UdpPeer>

L<Reflex/ACKNOWLEDGEMENTS>
L<Reflex/ASSISTANCE>
L<Reflex/AUTHORS>
L<Reflex/BUGS>
L<Reflex/BUGS>
L<Reflex/CONTRIBUTORS>
L<Reflex/COPYRIGHT>
L<Reflex/LICENSE>
L<Reflex/TODO>

=cut
