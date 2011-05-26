# A simple socket client.  Generic enough to be used for INET and UNIX
# sockets, although we may need to specialize for each kind later.

# TODO - This is a simple strawman implementation.  It needs
# refinement.

package Reflex::Client;
use Moose;
use Reflex::Stream;

extends 'Reflex::Connector';
with 'Reflex::Role::Collectible';
use Reflex::Trait::Watched qw(watches);

has protocol => (
	is      => 'rw',
	isa     => 'Str',
	default => 'Reflex::Stream',
);

watches connection => (
	isa     => 'Maybe[Reflex::Stream]',
	# Maps $self->put() to $self->connection()->put().
	# TODO - Would be nice to have something like this for outbout
	# events.  See on_connection_data() later in this module for more.
	handles => ['put'],
);

sub on_connection {
	my ($self, $args) = @_;

	$self->connection(
		$self->protocol()->new(
			handle => $args->{socket},
			rd     => 1,
		)
	);

	$self->emit(event => "connected", args => {});
}

sub on_error {
	my ($self, $args) = @_;
	# TODO - Emit rather than warn.
	warn "$args->{errfun} error $args->{errnum}: $args->{errstr}\n";
}

sub on_connection_closed {
	my ($self, $args) = @_;
	$self->connection()->stop();
	# TODO - Emit rather than warn.
	warn "server closed connection.\n";
}

sub on_connection_failure {
	my ($self, $args) = @_;
	$self->connection()->stop();
	# TODO - Emit rather than warn.
	warn "$args->{errfun} error $args->{errnum}: $args->{errstr}\n";
}

# This odd construct lets us rethrow a low-level event as a
# higher-level event.  It's similar to the way Moose "handles" works,
# although in the other (outbound) direction.
# TODO - It's rather inefficient to rethrow like this at runtime.
# Some compile- or init-time remapping construct would be better.
sub on_connection_data {
	my ($self, $args) = @_;
	$self->emit( event => "data", args => $args );
}

sub stop {
	my $self = shift;
	$self->connection(undef);
	$self->stopped();
};

1;

__END__

=head1 NAME

Reflex::Client - A non-blocking socket client.

=head1 SYNOPSIS

This is a complete working TCP echo client.  It's the version of
eg/eg-35-tcp-client.pl available at the time of this writing.

	use lib qw(../lib);

	{
		package TcpEchoClient;
		use Moose;
		extends 'Reflex::Client';

		sub on_client_connected {
			my ($self, $args) = @_;
			$self->connection()->put("Hello, world!\n");
		};

		sub on_client_data {
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

=head1 DESCRIPTION

Reflex::Client is scheduled for substantial changes.  One of its base
classes, Reflex::Handle, will be deprecated in favor of
Reflex::Role::Readable and Reflex::Role::Writable.  Hopefully
Reflex::Client's interfaces won't change much as a result, but
there are no guarantees.
Your ideas and feedback for Reflex::Client's future implementation
are welcome.

Reflex::Client is a high-level base class for non-blocking socket
clients.  As with other Reflex::Base classes, this one may be
subclassed, composed with "has", or driven inline with promises.

=head2 Attributes

Reflex::Client extends (and includes the attributes of)
Reflex::Connector, which extends Reflex::Handle.  It also provides its
own attributes.

=head3 protocol

The "protocol" attribute contains the name of a class that will handle
I/O for the client.  It contains "Reflex::Stream" by default.

Protocol classes should extend Reflex::Stream or at least follow its
interface.

=head2 Public Methods

Reflex::Client extends Reflex::Handle, but it currently provides no
additional methods.

=head2 Events

Reflex::Client emits some of its own high-level events based on its
components' activities.

=head3 connected

Reflex::Client emits "connected" to notify consumers when the client
has connected, and it's safe to begin sending data.

=head3 data

Reflex::Client emits stream data with the "data" event.  This event is
provided by Reflex::Stream.  Please see L<Reflex::Stream/data> for the
most current documentation.

=head1 EXAMPLES

eg/eg-35-tcp-client.pl subclasses Reflex::Client as TcpEchoClient.

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
