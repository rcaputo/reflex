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
	default => '127.0.0.1',
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
			$self->handle(undef);

			return;
		}
	}
}

sub on_handle_writable {
	my ($self, $args) = @_;

	# Not watching anymore.
	$self->wr(0);
	$self->handle(undef);

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
		},
	);
}

1;

__END__

=head1 NAME

Reflex::Connector - Connect to a server without blocking.

=head1 SYNOPSIS

This is an incomplete excerpt from Reflex::Client.  See that module's
source for a more complete example.

	package SomeKindaClient;
	use Moose;
	extends 'Reflex::Connector';

	sub on_connector_success {
		my ($self, $args) = @_;

		# Do something with $arg->{socket} here.
	}

	sub on_connector_failure {
		my ($self, $args) = @_;
		warn "$args->{errfun} error $args->{errnum}: $args->{errstr}\n";
		$self->stop();
	}

Reflex objects may also be used in condvar-like ways.  This excerpts
from eg/eg-38-promise-client.pl in the distribution.

	my $connector = Reflex::Connector->new(remote_port => 12345);
	my $event = $connector->next();

	if ($event->{name} eq "failure") {
		eg_say("connection error $event->{arg}{errnum}: $event->{arg}{errstr}");
		exit;
	}

	eg_say("Connected.");
	# Do something with $event->{arg}{socket}.

=head1 DESCRIPTION

Reflex::Connector performs a non-blocking connect() object on a plain
socket.  It extends Reflex::Handle to wait for the connection without
blocking the rest of a program.

By default, it will create its own TCP socket.  A program can provide
a specially prepared socket via the inherited "handle" attribute.

Two other attributes, "remote_addr" and "remote_port" specify where to
connect the socket.

This connector was written with TCP in mind, but it's intended to also
be useful for other connected sockets.

=head2 Attributes

Reflex::Connector supplies its own attributes in addition to those
provided by Reflex::Handle.

=head3 remote_addr

The "remote_addr" attribute specifies the address of a remote server.
It defaults to "127.0.0.1".

=head3 remote_port

The "remote_port" attribute sets the port of the server to which it
will attempt a connection.  The remote port may be an integer or the
symbolic port name from /etc/services.

=head2 Methods

Reflex::Connector inherits its methods from Reflex::Handle.  It
doesn't add new methods at this time.

=head2 Events

Reflex::Connector emits some events, which may be mapped to a
subclass' methods, or to handlers in a container object.  Please see
L<Reflex> and L<Reflex::Callbacks> for more information.

=head3 failure

Revlex::Connector emits a "failure" event if it can't establish a
connection.  Failure events include a few, fairly standard parameters:

=over 2

=item * socket - Undefined, since a connection could not be made.

=item * errnum - The numeric value of $! at the time of error.

=item * errstr - The string value of $! at the time of error.

=item * errfun - A brief description of the function call that failed.

=back

=head3 success

The "success" event is emitted if a connection has been established.
It will return a "socket", the value of which is the connected socket.

=head2 EXAMPLES

L<Reflex::Client> extends Reflex::Connector to include a
Reflex::Stream when the socket is connected.

eg/eg-38-promise-client.pl shows how to use Reflex::Connector in a
condvar-like fashion.

=head1 SEE ALSO

L<Reflex>
L<Reflex::Client>

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
