# vim: ts=2 sw=2 noexpandtab
# A TCP echo client.
# Strawman use cases for Reflex::Stream and Reflex::Connector.

use lib qw(../lib);

{
	package TcpEchoClient;
	use Moose;
	extends 'Reflex::Client';

	sub on_client_connected {
		my ($self, $args) = @_;
		$self->connection()->put("Hello, world!\n");
	};

	sub on_connection_data {
		my ($self, $args) = @_;

		# Not chomped.
		warn "got from server: $args->{data}";

		# Disconnect after we receive the echo.
		$self->stop();
	}
}

TcpEchoClient->new(port => 12345)->run_all();
