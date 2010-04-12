# A TCP echo client.
# Strawman use cases for Reflex::Stream and Reflex::Connector.

use lib qw(./lib ../lib);

{
	package TcpEchoClient;
	use Moose;
	extends 'Reflex::Client';

	after on_my_connected => sub {
		my ($self, $args) = @_;
		$self->connection()->put("Hello, world!\n");
	};

	sub on_connection_stream {
		my ($self, $args) = @_;

		# Not chomped.
		warn "got from server: $args->{data}";

		# Disconnect after we receive the echo.
		$self->stop();
	}
}

TcpEchoClient->new(
	remote_addr => '127.0.0.1',
	remote_port => 12345,
)->run_all();
