package Reflex::UdpPeer;
use Moose;
extends 'Reflex::Base';

has socket => (
	is        => 'rw',
	isa       => 'Maybe[FileHandle]',
	required  => 1,
);

with 'Reflex::Role::Recving' => {
	handle      => 'socket',
	method_send => 'send',
	method_stop => 'stop',
	cb_datagram => 'on_datagram',
	cb_error    => 'on_error',
};

1;

__END__

=head1 NAME

Reflex::UdpPeer - Base class for non-blocking UDP networking peers.

=head1 SYNOPSIS

TODO - Rewritten.  Need to rewrite docs, too.

Inherit it.

	package Reflex::Udp::Echo;
	use Moose;
	extends 'Reflex::UdpPeer';

	sub on_socket_datagram {
		my ($self, $args) = @_;
		my $data = $args->{datagram};

		if ($data =~ /^\s*shutdown\s*$/) {
			$self->stop_socket_readable();
			return;
		}

		$self->send(
			datagram    => $data,
			remote_addr => $args->{remote_addr},
		);
	}

	sub on_socket_error {
		my ($self, $args) = @_;
		warn "$args->{op} error $args->{errnum}: $args->{errstr}";
		$self->destruct();
	}

Use it as a helper.

	package Reflex::Udp::Echo;
	use Moose;
	extends 'Reflex::Base';
	use Reflex::UdpPeer;

	has port => ( isa => 'Int', is => 'ro' );

	has peer => (
		isa     => 'Maybe[Reflex::UdpPeer]',
		is      => 'rw',
		traits  => ['Reflex::Trait::Observed'],
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

Compose objects with its base role.

	# See L<Reflex::Role::Recving>.

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
L<Reflex::Base>
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
