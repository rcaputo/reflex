package Reflex::Role::Connecting;
use MooseX::Role::Parameterized;
use Reflex::Util::Methods qw(emit_an_event emit_and_stopped method_name);

use Errno qw(EWOULDBLOCK EINPROGRESS);
use Socket qw(SOL_SOCKET SO_ERROR inet_aton pack_sockaddr_in);

parameter socket => (
	isa     => 'Str',
	default => 'socket',
);

parameter address => (
	isa     => 'Str',
	default => 'address',
);

parameter port => (
	isa       => 'Str',
	default   => 'port',
);

parameter cb_success  => method_name("on", "socket", "success");
parameter cb_error    => method_name("on", "socket", "error");

role {
	my $p = shift;

	my $socket      = $p->socket();
	my $address     = $p->address();
	my $port        = $p->port();

	my $cb_success  = $p->cb_success();
	my $cb_error    = $p->cb_error();

	my $internal_writable = "on_" . $socket . "_writable";
	my $internal_stop     = "stop_" . $socket . "_writable";

	with 'Reflex::Role::Writable' => {
		handle  => $socket,
	};

	# Work around a Moose edge case.
	sub BUILD {}

	after BUILD => sub {
		my ($self, $args) = @_;

		# TODO - Needs to be a lot more robust.  See
		# POE::Wheel::SocketFactory for platform issues.
		#
		# TODO - Verify this makes the connect() non-blocking.  Need to
		# make the socket non-blocking if we connect() first.

		# Create a handle if we need to.
		unless ($self->$socket()) {
			$self->$socket(IO::Socket::INET->new(Proto => 'tcp'));
		}

		my $handle = $self->$socket();

		my $packed_address;
		if ($handle->isa("IO::Socket::INET")) {
			# TODO - Need a non-bollocking resolver.
			my $inet_address = inet_aton($self->$address());
			$packed_address = pack_sockaddr_in($self->$port(), $inet_address);
		}
		else {
			die "unknown socket class: ", ref($handle);
		}

		# TODO - Make sure we're in the right session.
		my $method_start = "start_${socket}_writable";
		$self->$method_start();

		# Begin connecting.
		unless (connect($handle, $packed_address)) {
			if ($! and ($! != EINPROGRESS) and ($! != EWOULDBLOCK)) {
				$self->$cb_error(
					{
						socket  => undef,
						errnum  => ($!+0),
						errstr  => "$!",
						errfun  => "connect",
					},
				);

				$self->$internal_stop();
				return;
			}
		}
	};

	method $internal_writable => sub {
		my ($self, $args) = @_;

		# Not watching anymore.
		$self->$internal_stop();

		# Throw a failure if the connection failed.
		$! = unpack('i', getsockopt($args->{handle}, SOL_SOCKET, SO_ERROR));
		if ($!) {
			$self->$cb_error(
				{
					socket  => undef,
					errnum  => ($!+0),
					errstr  => "$!",
					errfun  => "connect",
				},
			);
			return;
		}

		$self->$cb_success(
			{
				socket  => $args->{handle},
			}
		);
		return;
	};

	method $cb_success  => emit_an_event("success");
	method $cb_error    => emit_an_event("error");
};

1;

__END__

=head1 NAME

Reflex::Role::Connecting - add non-blocking client connecting to a class

=head1 SYNOPSIS

	package Reflex::Connector;

	use Moose;
	extends 'Reflex::Base';

	has socket => (
		is        => 'rw',
		isa       => 'FileHandle',
	);

	has port => (
		is => 'ro',
		isa => 'Int',
	);

	has address => (
		is      => 'ro',
		isa     => 'Str',
		default => '127.0.0.1',
	);

	with 'Reflex::Role::Connecting' => {
		connector   => 'socket',      # Default!
		address     => 'address',     # Default!
		port        => 'port',        # Default!
		cb_success  => 'on_connection',
		cb_error    => 'on_error',
	};

	1;

=head1 DESCRIPTION

Reflex::Role::Connecting is a Moose parameterized role that adds
non-blocking connect() behaviors to classes.

See Reflex::Connector if you prefer runtime composition with objects,
or if Moose syntax just gives you the willies.

=head2 Required Role Parameters

None.

=head2 Optional Parameters

=head3 address

C<address> defines the attribute that will contain the address to
which the class will connect.  The address() attribute will be used if
the class doesn't override the name.  The default address will be the
IPv4 localhost, "127.0.0.1".

=head3 port

C<port> defines the attribute that will contain the port to which this
role will connect.  By default, the role will use the port()
attribute.  There is no default port() value.

=head3 socket

The C<socket> parameter must contain the name of an attribute that
contains the connecting socket handle.  "socket" will be used if a
name isn't provided.  A C<socket> must be provided if two or more
client connections will be created from the same class, otherwise they
will both attempt to use the same "socket".

Reflex::Role::Connecting will create a plain TCP socket if C<socket>'s
attribute is empty at connecting time.  A class may build its own
socket, if it needs to set special options.

The role will generate additional methods and callbacks that are named
after C<socket>.  For example, if C<socket> contains XYZ, then the
default error callback will be on_XYZ_error().

=head3 cb_success

C<cb_success> overrides the default name for the class's successful
connection handler method.  This handler will be called whenever a
client connection is successfully connected.

The default method name is "on_${socket}_success", where $socket is
the name of the socket attribute.  This role defines a default
callback that emits an "success" event.

All callback methods receive two parameters: $self and an anonymous
hash containing information specific to the callback.  In
C<cb_success>'s case, the anonymous hash contains one value: the
socket that has just established a connection.

=head3 cb_error

C<cb_error> names the $self method that will be called whenever
connect() encounters an error.  By default, this method will be the
catenation of "on_", the C<socket> name, and "_error".  As in
on_XYZ_error(), if the socket attribute is named "XYZ".  The role
defines a default callback that will emit an "error" event with
cb_error()'s parameters.

C<cb_error> callbacks receive two parameters, $self and an anonymous
hashref of named values specific to the callback.  Reflex error
callbacks include three standard values.  C<errfun> contains a
single word description of the function that failed.  C<errnum>
contains the numeric value of C<$!> at the time of failure.  C<errstr>
holds the stringified version of C<$!>.

Values of C<$!> are passed as parameters since the global variable may
change before the callback can be invoked.

When overriding this callback, please be sure to call stopped(), which
is provided by Reflex::Role::Collectible.  Calling stopped() is vital
for collectible objects to be released from memory when managed by
Reflex::Collection.

=head1 EXAMPLES

TODO - I'm sure there are some.

=head1 SEE ALSO

L<Reflex>
L<Reflex::Role::Accepting>
L<Reflex::Acceptor>
L<Reflex::Connector>

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
