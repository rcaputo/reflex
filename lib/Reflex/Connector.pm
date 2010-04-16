# A socket connector.
# TODO - This is an intitial strawman implementation.

package Reflex::Connector;
use Moose;
extends 'Reflex::Handle';

use Errno qw(EWOULDBLOCK EINPROGRESS);
use Socket qw(SOL_SOCKET SO_ERROR inet_aton pack_sockaddr_in);

has remote_addr => (
	is      => 'ro',
	isa     => 'Str',
	default => 'localhost',
);

# TODO - Make it an integer.  Coerce from string by resolving
# service name.
has remote_port => (
	is       => 'ro',
	isa      => 'Str',
	required => 1,
);

has '+handle' => (
	default => sub { IO::Socket::INET->new(Proto => 'tcp') }
);

sub BUILD {
	my ($self, $args) = @_;

	# TODO - See POE::Wheel::SocketFactory for platform issues.
	#
	# TODO - Verify this makes the connect() non-blocking.  Need to
	# make the socket non-blocking if we connect() first.
	$self->wr(1);

	my $handle = $self->handle();

	my $packed_address;
	if ($handle->isa("IO::Socket::INET")) {
		# TODO - Non-bollocking resolver.
		my $inet_address = inet_aton($self->remote_addr());
		$packed_address = pack_sockaddr_in($self->remote_port(), $inet_address);
	}
	else {
		die "unknown socket class: ", ref($handle);
	}

	unless (connect($self->handle(), $packed_address)) {
		if ($! and ($! != EINPROGRESS) and ($! != EWOULDBLOCK)) {
			$self->emit(
				event => "failure",
				args  => {
					socket  => undef,
					errnum  => ($!+0),
					errstr  => "$!",
					errfun  => "connect",
				},
			);
			$self->wr(0);
			return;
		}
	}
}

sub on_handle_writable {
	my ($self, $args) = @_;

	# Not watching anymore.
	$self->wr(0);

	# Throw a failure if the connection failed.
	$! = unpack('i', getsockopt($args->{handle}, SOL_SOCKET, SO_ERROR));
	if ($!) {
		$self->emit(
			event => "failure",
			args  => {
				socket  => undef,
				errnum  => ($!+0),
				errstr  => "$!",
				errfun  => "connect",
			},
		);
		return;
	}

	$self->emit(
		event => "success",
		args  => {
			socket  => $args->{handle},
			errnum  => ($!+0),
			errstr  => "$!",
			errfun  => "connect",
		},
	);
}

1;
