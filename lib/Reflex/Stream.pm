package Reflex::Stream;
# vim: ts=2 sw=2 noexpandtab

use Moose;
extends 'Reflex::Base';
use Reflex::Callbacks qw(make_emitter make_terminal_emitter);

has handle => ( is => 'rw', isa => 'FileHandle', required => 1 );
has active => ( is => 'ro', isa => 'Bool', default => 1 );

with 'Reflex::Role::Streaming' => {
	att_active  => 'active',
	att_handle  => 'handle',
	method_put  => 'put',
	method_stop => 'stop',
	cb_error    => make_emitter(on_error => "error"),
	cb_data     => make_emitter(on_data  => "data"),
	cb_closed   => make_terminal_emitter(on_closed => "closed"),
};

__PACKAGE__->meta->make_immutable;

1;

__END__

=head1 NAME

Reflex::Stream - Buffered, translated I/O on non-blocking handles.

=head1 SYNOPSIS

This is a complete Reflex::Stream subclass.  It echoes whatever it
receives back to the sender.  Its error handlers are compatible with
Reflex::Collection.

	package EchoStream;
	use Moose;
	extends 'Reflex::Stream';

	sub on_data {
		my ($self, $event) = @_;
		$self->put($event->octets());
	}

	sub on_error {
		my ($self, $event) = @_;
		warn(
			$event->error_function(),
			" error ", $event->error_number(),
			": ", $event->error_string(),
		);
		$self->stopped();
	}

	sub DEMOLISH {
		print "EchoStream demolished as it should.\n";
	}

	1;

Since it extends Reflex::Base, it may also be used like a condavr or
promise.  This incomplte example comes from eg/eg-38-promise-client.pl:

	my $stream = Reflex::Stream->new(
		handle => $socket
		rd     => 1,
	);

	$stream->put("Hello, world!\n");

	my $event = $stream->next();
	if ($event->{name} eq "data") {
		print "Got echo response: $event->{arg}{data}";
	}
	else {
		print "Unexpected event: $event->{name}";
	}

=head1 DESCRIPTION

Reflex::Stream reads from and writes to a file handle, most often a
socket.  It is almost entirely implemented in Reflex::Role::Streaming.
That role's documentation contains important details that won't be
covered here.

=head2 Public Attributes

=head3 handle

Reflex::Stream implements a single attribute, handle, that must be set
to the stream's file handle (which can be a socket or something).

=head2 Public Methods

Reflex::Role::Streaming provides all of Reflex::Stream's methods.
Reflex::Stream however renames them to make more sense in a class.

=head3 put

The put() method writes one or more chunks of raw octets to the
stream's handle.  Any data that cannot be written immediately will be
buffered until Reflex::Role::Streaming can write it later.

Please see L<Reflex::Role::Streaming/method_put> for details.

=head2 Callbacks

=head3 on_closed

Subclasses may define on_closed() to be notified when the remote end
of the stream has closed for output.  No further data will be received
after receipt of this callback.

on_closed() receives no parameters of note.

The default on_closed() callback will emit a "closed" event.
It will also call stopped().

When overriding this callback, please be sure to call stopped(), which
is provided by Reflex::Role::Collectible.  Calling stopped() is vital
for collectible objects to be released from memory when managed by
Reflex::Collection.

=head3 on_data

on_data() will be called whenever Reflex::Stream receives data.  It
will include one named parameter in $_[1], "data", containing raw
octets received from the stream.

	sub on_data {
		my ($self, $param) = @_;
		print "Got data: $param->{data}\n";
	}

The default on_data() callback will emit a "data" event.

=head3 on_error

on_error() will be called if an error occurs reading from or writing
to the stream's handle.  Its parameters are the usual for Reflex:

	sub on_error {
		my ($self, $param) = @_;
		print "$param->{errfun} error $param->{errnum}: $param->{errstr}\n";
	}

The default on_error() callback will emit a "error" event.
It will also call stopped().

When overriding this callback, please be sure to call stopped(), which
is provided by Reflex::Role::Collectible.  Calling stopped() is vital
for collectible objects to be released from memory when managed by
Reflex::Collection.

=head2 Public Events

Reflex::Stream emits stream-related events, naturally.

=head3 closed

The "closed" event indicates that the stream is closed.  This is most
often caused by the remote end of a socket closing their connection.

See L</on_closed> for more details.

=head3 data

The "data" event is emitted when a stream produces data to work with.
It includes a single parameter, also "data", containing the raw octets
read from the handle.

See L</on_data> for more details.

=head3 error

Reflex::Stream emits "error" when any of a number of calls fails.

See L</on_error> for more details.

=head1 EXAMPLES

eg/EchoStream.pm in the distribution is the same EchoStream that
appears in the SYNOPSIS.

eg/eg-38-promise-client.pl shows a lengthy inline usage of
Reflex::Stream and a few other classes.

=head1 SEE ALSO

L<Reflex>
L<Reflex::Listener>
L<Reflex::Connector>
L<Reflex::UdpPeer>

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
