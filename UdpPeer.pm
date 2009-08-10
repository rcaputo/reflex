# A UDP peer.

package UdpPeer;
use Moose;
extends 'Stage';
use Handle;

has port => (
	isa => 'Int',
	is  => 'ro',
);

has handle => (
	isa => 'Handle|Undef',
	is  => 'rw',
);

has max_datagram_size => (
	isa     => 'Int',
	is      => 'rw',
	default => 1024,
);

sub BUILD {
	my $self = shift;

	$self->handle(
		Handle->new(
			handle => IO::Socket::INET->new(
				Proto     => 'udp',
				LocalPort => $self->port(),
			),
			rd => 1,
			observers => [
				{
					observer => $self,
					role     => 'remote',
				}
			],
		)
	);
	undef;
}

sub on_remote_read {
	my ($self, $args) = @_;

	my $remote_address = recv(
		$args->{handle},
		my $datagram = "",
		$self->max_datagram_size(),
		0
	);

	$self->emit(
		event => "datagram",
		args => {
			datagram    => $datagram,
			remote_addr => $remote_address,
		},
	);
}

sub send {
	my ($self, @args) = @_;

	my $args = $self->_check_args(
		\@args,
		[ 'datagram', 'remote_addr' ],
		[ ],
	);

	return if send(
		$self->handle()->handle(), # TODO - Ugh!
		$args->{datagram},
		0,
		$args->{remote_addr},
	) == length($args->{datagram});

	$self->emit(
		event => "error",
		args  => {
			op      => "send",
			errnum  => $! + 0,
			errstr  => "$!",
		},
	);
}

sub destruct {
	my $self = shift;
	# TODO - Syntactic sugar? This will be common.
	$self->ignore(observed => $self->handle());
	$self->handle(undef);
}

1;
