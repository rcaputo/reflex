# A TCP echo server.
# Implements and demonstrates collections of related objects.
# Also composition to create a simple echo server.

use lib qw(../lib);

# Define the server.

{
	package TcpEchoServer;

	use Moose;
	extends 'Reflex::Acceptor';
	use Reflex::Collection;
	use EchoStream;

	has clients => (
		is      => 'rw',
		isa     => 'Reflex::Collection',
		default => sub { Reflex::Collection->new() },
		handles => { remember_client => "remember" },
	);

	sub on_accept {
		my ($self, $args) = @_;
		$self->remember_client(
			EchoStream->new(
				handle => $args->{socket},
				rd     => 1,
			)
		);
	}

	sub on_error {
		my ($self, $args) = @_;
		warn "$args->{errfun} error $args->{errnum}: $args->{errstr}\n";
		$self->stop();
	}
}

# Now actually user the server.

my $port = 12345;
print "Setting up TCP echo server on localhost:$port...\n";
TcpEchoServer->new(
	listener => IO::Socket::INET->new(
		LocalAddr => '127.0.0.1',
		LocalPort => $port,
		Listen    => 5,
		Reuse     => 1,
	),
)->run_all();
