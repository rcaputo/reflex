# A TCP echo client.
# Strawman use cases for Reflex::Stream and Reflex::Connector.

use lib qw(./lib ../lib);

{
	package TcpEchoClient;
	use Moose;
	extends 'Reflex::Client';

	after on_my_connected => sub {
		my ($self, $args) = @_;
		$self->server()->put("Hello, world!\n");
	};

	sub on_server_stream {
		my ($self, $args) = @_;

		# Not chomped.
		warn "got from server: $args->{data}";

		# Close the connection after we've got the echo.
		# TODO - Moosey way to clear this?
		# TODO - Socket shutdown?
		$self->server(undef);
	}
}

TcpEchoClient->new(
	remote_addr => '127.0.0.1',
	remote_port => 12345,
)->run_all();
