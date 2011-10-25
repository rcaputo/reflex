package Reflex::Connector;
# vim: ts=2 sw=2 noexpandtab

use Moose;
extends 'Reflex::Base';
use Reflex::Callbacks qw(make_emitter);

has active  => ( is => 'ro', isa => 'Bool', default => 1 );
has address => ( is => 'ro', isa => 'Str', default  => '127.0.0.1' );
has port    => ( is => 'ro', isa => 'Int' );
has socket  => ( is => 'rw', isa => 'FileHandle' );

with 'Reflex::Role::Connecting' => {
	att_connector => 'socket',      # Default!
	att_address   => 'address',     # Default!
	att_port      => 'port',        # Default!
	cb_success    => make_emitter(on_connection => "connection"),
	cb_error      => make_emitter(on_error => "error"),
};

1;

__END__

=head1 NAME

Reflex::Connector - non-blocking client socket connector

=head1 SYNOPSIS

This is a partial excerpt from eg/eg-38-promise-client.pl

	use Reflex::Connector;
	use Reflex::Stream;

	my $connector = Reflex::Connector->new(port => 12345);

	my $event = $connector->next();
	if ($event->{name} eq "failure") {
		die("error $event->{arg}{errnum}: $event->{arg}{errstr}");
	}

	my $stream = Reflex::Stream->new(
		handle => $event->{arg}{socket},
	);

=head1 DESCRIPTION

Reflex::Connector asynchronously establishes a client connection.  It
is almost entirely implemented in Reflex::Role::Connecting.  That
role's documentation contains important details that won't be covered
here.

=head2 Public Attributes

=head3 address

C<address> defines the remote address to which Reflex::Connector will
attempt a connection.  It defaults to "127.0.0.1".
See Reflex::Role::Connecting for more details.

=head3 port

C<port> defines the remote port to which Reflex::Connector will
attempt a connection.  It has no default.
See Reflex::Role::Connecting for more details.

=head3 socket

Reflex::Connector will provide its own socket by default.  It also
accepts a C<socket> that may be configured in custom ways.

See C<connector> in Reflex::Role::Connecting for more details.

=head2 Public Methods

None.

=head2 Callbacks

=head3 on_connection

C<on_connection> is called when Reflex::Connector establishes a
connection.
Reflex::Role::Connecting explains the data returned with
C<on_connection>.
If necessary, that role will also define a default C<on_connection>
handler that emits "success" event.  (TODO - Does this make sense?)

=head3 on_error

C<on_error> is called whenever a connection fails for some reason.
returns an error.  Reflex::Role::Connecting explains the data returned
with C<on_error>.  If necessary, that role will also define a default
C<on_error> handler that emits an "error" event.

=head2 Public Events

Reflex::Connector emits events related to establishing clinet
connections.  These events are defined by Reflex::Role::Connecting,
and they will be explained there.

=head3 success

If no C<on_connection> handler is set, then Reflex::Connector will
emit a "success" event if the connection is successfuly established.
Reflex::Role::Connecting explains this event in more detail.

=head3 error

If no C<on_error> handler is set, then Reflex::Connector will emit an
"error" event whenever a connection fails to establish.
Reflex::Role::Connecting explains this event in more detail.

=head1 EXAMPLES

The SYNOPSIS is a partial excerpt from eg/eg-38-promise-client.pl

eg/eg-35-tcp-client.pl is a more callbacky client.

=head1 SEE ALSO

L<Reflex>
L<Reflex::Role::Connecting>
L<Reflex::Role::Accepting>
L<Reflex::Acceptor>

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
