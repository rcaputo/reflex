package Reflex::Role::Connecting;
use MooseX::Role::Parameterized;
use Reflex::Util::Methods qw(emit_an_event emit_and_stopped method_name);

use Errno qw(EWOULDBLOCK EINPROGRESS);
use Socket qw(SOL_SOCKET SO_ERROR inet_aton pack_sockaddr_in);

parameter connector => (
	isa     => 'Str',
	default => 'connector',
);

parameter address => (
	isa     => 'Str',
	default => 'address',
);

parameter port => (
	isa     => 'Str',
	default => 'port',
);

parameter cb_success  => method_name("on", "connector", "success");
parameter cb_error    => method_name("on", "connector", "error");

role {
	my $p = shift;

	my $connector   = $p->connector();
	my $address     = $p->address();
	my $port        = $p->port();

	my $cb_success  = $p->cb_success();
	my $cb_error    = $p->cb_error();

	my $internal_writable = "on_" . $connector . "_writable";
	my $internal_stop     = "stop_" . $connector . "_writable";

	with 'Reflex::Role::Writable' => {
		handle  => $connector,
	};

	after BUILD => sub {
		my ($self, $args) = @_;

		# TODO - Needs to be a lot more robust.  See
		# POE::Wheel::SocketFactory for platform issues.
		#
		# TODO - Verify this makes the connect() non-blocking.  Need to
		# make the socket non-blocking if we connect() first.

		# Create a handle if we need to.
		unless ($self->$connector()) {
			$self->$connector(IO::Socket::INET->new(Proto => 'tcp'));
		}

		my $handle = $self->$connector();

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
		my $method_start = "start_${connector}_writable";
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

	method "on_${connector}_writable" => sub {
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
