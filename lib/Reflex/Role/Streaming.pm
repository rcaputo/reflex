package Reflex::Role::Streaming;
use MooseX::Role::Parameterized;
use Reflex::Util::Methods qw(emit_an_event emit_and_stopped method_name);

use Scalar::Util qw(weaken);

parameter handle => (
	isa     => 'Str',
	default => 'handle',
);

parameter cb_data     => method_name("on", "handle", "data");
parameter cb_error    => method_name("on", "handle", "error");
parameter cb_closed   => method_name("on", "handle", "closed");
parameter method_put  => method_name("put", "handle", undef);
parameter method_stop => method_name("stop", "handle", undef);

role {
	my $p = shift;

	my $h         = $p->handle();
	my $cb_data   = $p->cb_data();
	my $cb_error  = $p->cb_error();
	my $cb_closed = $p->cb_closed();

	with 'Reflex::Role::Collectible';

	with 'Reflex::Role::Readable' => {
		handle  => $h,
		active  => 1,
	};

	with 'Reflex::Role::Writable' => {
		handle  => $h,
	};

	has out_buffer => (
		is      => 'rw',
		isa     => 'ScalarRef',
		default => sub { my $x = ""; \$x },
	);

	my $resume_writable = "resume_${h}_writable";
	my $pause_writable  = "pause_${h}_writable";

	method "on_${h}_readable" => sub {
		my ($self, $arg) = @_;

		my $octet_count = sysread($arg->{handle}, my $buffer = "", 65536);

		# Got data.
		if ($octet_count) {
			$self->$cb_data({ data => $buffer });
			return;
		}

		# EOF
		if (defined $octet_count) {
			$self->$cb_closed({ });
			return;
		}

		# Quelle erreur!
		$self->$cb_error(
			{
				errnum => ($! + 0),
				errstr => "$!",
				errfun => "sysread",
			}
		);
	};

	method "on_${h}_writable" => sub {
		my ($self, $arg) = @_;

		my $out_buffer = $self->out_buffer();
		my $octet_count = syswrite($self->$h(), $$out_buffer);

		# Hard error.
		unless (defined $octet_count) {
			$self->$cb_error(
				{
					errnum => ($! + 0),
					errstr => "$!",
					errfun => "syswrite",
				}
			);
			return;
		}

		# Remove what we wrote.
		substr($$out_buffer, 0, $octet_count, "");

		# Pause writes if it all was flushed.
		return if length $$out_buffer;
		$self->$pause_writable();
		return;
	};

	method $p->method_put() => sub {
		my ($self, @chunks) = @_;

		# TODO - Benchmark string vs. array buffering.

		use bytes;

		my $out_buffer = $self->out_buffer();
		if (length $$out_buffer) {
			$$out_buffer .= $_ foreach @chunks;
			return length $$out_buffer;
		}

		# Try to flush 'em all.
		while (@chunks) {
			my $next = shift @chunks;
			my $octet_count = syswrite($self->$h(), $next);

			# Hard error.
			unless (defined $octet_count) {
				$self->$cb_error(
					{
						errnum => ($! + 0),
						errstr => "$!",
						errfun => "syswrite",
					}
				);
				return;
			}

			# Wrote it all!  Whooooo!
			next if $octet_count == length $next;

			# Wrote less than all.  Save the rest, and turn on write
			# multiplexing.
			$$out_buffer = substr($next, $octet_count);
			$$out_buffer .= $_ foreach @chunks;

			$self->$resume_writable();
			return length $$out_buffer;
		}

		# Flushed it all.  Yay!
		return 0;
	};

	# Default callbacks that re-emit their parameters.
	method $cb_data   => emit_an_event("data");
	method $cb_error  => emit_and_stopped("error");
	method $cb_closed => emit_and_stopped("closed");

	method $p->method_stop() => sub {
		my $self = shift;
		$self->stop_handle_readable();
		$self->stop_handle_writable();
	};
};

1;

__END__

=head1 NAME

Reflex::Role::Streaming - add streaming I/O behavior to a class

=head1 SYNOPSIS

	use Moose;

	has socket => ( is => 'rw', isa => 'FileHandle', required => 1 );

	with 'Reflex::Role::Streaming' => {
		handle    => 'socket',
		cb_data   => 'on_socket_data',    # default
		cb_error  => 'on_socket_error',   # default
		cb_closed => 'on_socket_closed',  # default
	};

	sub on_socket_data {
		my ($self, $arg) = @_;
		$self->put_socket($arg->{data});
	}

	sub on_socket_error {
		my ($self, $arg) = @_;
		print "$arg->{errfun} error $arg->{errnum}: $arg->{errstr}\n";
		$self->stopped();
	}

	sub on_socket_closed {
		my $self = shift;
		print "Connection closed.\n";
		$self->stopped();
	}

=head1 DESCRIPTION

Reflex::Role::Streaming is a Moose parameterized role that adds
streaming I/O behavior to Reflex-based classes.  In the SYNOPSIS, a
filehandle named "socket" is turned into a NBIO stream by the addition
addition of Reflex::Role::Streaming.

See Reflex::Stream if you prefer runtime composition with objects, or
you just find Moose syntax difficult to handle.

=head2 Required Role Parameters

=head3 handle

The C<handle> parameter must contain the name of the attribute that
contains the handle to stream.  The name indirection allows the role
to generate methods that are unique to the handle.  For example, a
handle named "XYZ" would generate these methods by default:

	cb_closed   => "on_XYZ_closed",
	cb_data     => "on_XYZ_data",
	cb_error    => "on_XYZ_error",
	method_put  => "put_XYZ",

This naming convention allows the role to be used for more than one
handle in the same class.  Each handle will have its own name, and the
mixed in methods associated with them will also be unique.

=head2 Optional Role Parameters

=head3 cb_closed

C<cb_closed> names the $self method that will be called whenever
C<handle> has reached the end of readable data.  For sockets, this
means the remote endpoint has closed or shutdown for writing.

C<cb_closed> is by default the catenation of "on_", the C<handle>
name, and "_closed".  A handle named "XYZ" will by default trigger
on_XYZ_closed() callbacks.  The role defines a default callback that
will emit a "closed" event and call stopped(), which is provided by
Reflex::Role::Collectible.

Currently the second parameter to the C<cb_closed> callback contains
no parameters of note.

When overriding this callback, please be sure to call stopped(), which
is provided by Reflex::Role::Collectible.  Calling stopped() is vital
for collectible objects to be released from memory when managed by
Reflex::Collection.

=head3 cb_data

C<cb_data> names the $self method that will be called whenever the
stream for C<handle> has provided new data.  By default, it's the
catenation of "on_", the C<handle> name, and "_data".  A handle named
"XYZ" will by default trigger on_XYZ_data() callbacks.  The role
defines a default callback that will emit a "data" event with
cb_data()'s parameters.

All Reflex parameterized role calblacks are invoked with two
parameters: $self and an anonymous hashref of named values specific to
the callback.  C<cb_data> callbacks include a single named value,
C<data>, that contains the raw octets received from the filehandle.

=head3 cb_error

C<cb_error> names the $self method that will be called whenever the
stream produces an error.  By default, this method will be the
catenation of "on_", the C<handle> name, and "_error".  As in
on_XYZ_error(), if the handle is named "XYZ".  The role defines a
default callback that will emit an "error" event with cb_error()'s
parameters, then will call stopped() so that streams managed by
Reflex::Collection will be automatically cleaned up after stopping.

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

=head3 method_put

C<method_put> defines the name of a method that will put data octets
into the stream's output buffer.  The default name is "put_" followed
by the streaming handle's name, such as put_XYZ().

The put method takes an array of strings of raw octets:

	my $pending_count = $self->put_XYZ(
		"raw octets here", " and some more"
	);

The put method will try to flush the stream's output buffer
immediately.  Any data that cannot be flushed will remain in the
buffer.  The streaming code will attempt to flush it later when the
stream becomes writable again.

The put method returns the number of buffered octets waiting to be
flushed---zero if the buffer has been synchronously flushed.  If the
synchronous syswrite() fails, it will invoke C<cb_error> and return
undef.

=head1 EXAMPLES

TODO - I'm sure there are some.

=head1 SEE ALSO

L<Reflex>
L<Reflex::Role::Readable>
L<Reflex::Role::Writable>
L<Reflex::Stream>

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
