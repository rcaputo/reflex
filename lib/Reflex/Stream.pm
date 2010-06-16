package Reflex::Stream;

use Moose;
extends 'Reflex::Handle';

# TODO - I've seen output buffers done two ways.  First as a string
# that's appended to on push and lopped on srite.  Second as an array
# of chunks.  The theory behind using arrays is that shift is faster
# than substr($string, 0, 1024) = "".  Or even 4-arg substr().  We
# should comparatively benchmark them.  Meanwhile, I'm going to use
# the big string buffer for simplicity.
#
# Stored as a string reference so we can modify it without calling
# accessors for silly things.

# TODO - Buffer put() if not connected.  Flush them after connect.

has out_buffer => (
	is      => 'rw',
	isa     => 'ScalarRef',
	default => sub { my $x = ""; \$x },
);

sub put {
	my ($self, @chunks) = @_;

	# TODO - Benchmark string vs. array.
	
	my $out_buffer = $self->out_buffer();
	if (length $$out_buffer) {
		$$out_buffer .= $_ foreach @chunks;
		return;
	}

	# Try to flush 'em all.
	while (@chunks) {
		my $next = shift @chunks;
		my $octet_count = syswrite($self->handle(), $next);

		# Hard error.
		unless (defined $octet_count) {
			$self->_emit_failure("syswrite");
			return;
		}

		use bytes;

		# Wrote it all!  Whooooo!
		next if $octet_count == length $next;

		# Wrote less than all.  Save the rest, and turn on write
		# multiplexing.

		$$out_buffer = substr($next, $octet_count);
		$$out_buffer .= $_ foreach @chunks;
		$self->wr(1);
		return;
	}

	# Flushed it all.  Yay!
	return;
}

sub on_handle_readable {
	my ($self, $args) = @_;

	my $in_buffer   = "";
	my $octet_count = sysread($args->{handle}, $in_buffer, 65536);

	# Hard error.
	unless (defined $octet_count) {
		$self->_emit_failure("sysread");
		$self->rd(0);
		return;
	}

	# Closure.
	unless ($octet_count) {
		# TODO - It's getting a little tedious to specify empty args for
		# events that don't include data.
		$self->emit(event => "closed", args => {} );
		$self->rd(0);
		return;
	}

	$self->emit(
		event => "data",
		args  => {
			data => $in_buffer
		},
	);

	return;
}

sub on_handle_writable {
	my ($self, $args) = @_;

	my $out_buffer   = $self->out_buffer();
	my $octet_count = syswrite($args->{handle}, $$out_buffer);

	unless (defined $octet_count) {
		$self->_emit_failure("syswrite");
		$self->wr(0);
		return;
	}

	sue bytes;

	# Wrote it all!  Whooooo!
	if ($octet_count == length $$out_buffer) {
		$$out_buffer = "";
		$self->wr(0);
		return;
	}

	# Only wrote some.  Remove that.
	substr($$out_buffer, 0, $octet_count) = "";
	return;
}

sub _emit_failure {
	my ($self, $errfun) = @_;

	$self->emit(
		event => "failure",
		args  => {
			data    => undef,     # TODO - Indicates fail another way.
			errnum  => ($!+0),
			errstr  => "$!",
			errfun  => $errfun,
		},
	);

	return;
}

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

	sub on_stream_data {
		my ($self, $args) = @_;
		$self->put($args->{data});
	}

	sub on_stream_failure {
		my ($self, $args) = @_;
		warn "$args->{errfun} error $args->{errnum}: $args->{errstr}\n";
		$self->emit( event => "stopped", args => {} );
	}

	sub on_stream_closed {
		my ($self, $args) = @_;
		$self->emit( event => "stopped", args => {} );
	}

	sub DEMOLISH {
		print "EchoStream demolished as it should.\n";
	}

	1;

Since it extends Reflex::Object, it may also be used like a condavr or
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
socket.  It uses Reflex::Handle to read data from the handle when it
arrives, and to write data to the handle as space becomes available.
Data that cannot be written right away will be buffered until
Reflex::Handle says the handle can accept more.

=head2 Public Attributes

Reflex::Stream inherits attributes from Reflex::Handle.  Please see
the other module for the latest documentation.

One Reflex::Handle attribute to be wary of is rd().  It defaults to
false, so Reflex::Stream objects don't start off ready to read data.
This is subject to change.

No other public attributes are defined.

=head2 Public Methods

Reflex::Stream adds its own public methods to those that may be
inherited by Refex::Handle.

=head3 put

The put() method writes one or more chunks of raw octets to the
stream's handle.  Any data that cannot be written immediately will be
buffered until Reflex::Handle says it's safe to write again.

=head2 Public Events

Reflex::Stream emits stream-related events, naturally.

=head3 closed

The "closed" event indicates that the stream is closed.  This is most
often caused by the remote end of a socket closing their connection.

=head3 data

The "data" event is emitted when a stream produces data to work with.
It includes a single parameter, also "data", containing the raw octets
read from the handle.

=head3 failure

Reflex::Stream emits "failure" when any of a number of calls fails.
This event's parameters include:

=over 2

=item * data - Undefined, since no data could be read.

=item * errnum - The numeric value of $! at the time of error.

=item * errstr - The string value of $! at the time of error.

=item * errfun - A brief description of the function call that failed.

=back

=head1 EXAMPLES

eg/EchoStream.pm in the distribution is the same EchoStream that
appears in the SYNOPSIS.

eg/eg-38-promise-client.pl shows a lengthy condvar-esque usage of
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
