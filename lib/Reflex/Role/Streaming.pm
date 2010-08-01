package Reflex::Role::Streaming;
use Reflex::Role;

attribute_parameter handle      => "handle";
callback_parameter  cb_data     => qw( on handle data );
callback_parameter  cb_error    => qw( on handle error );
callback_parameter  cb_closed   => qw( on handle closed );
method_parameter    method_put  => qw( put handle _ );
method_parameter    method_stop => qw( stop handle _ );

role {
	my $p = shift;

	my $h           = $p->handle();
	my $cb_error    = $p->cb_error();
	my $method_read = "_on_${h}_readable";
	my $method_put  = $p->method_put();

	my $method_writable = "_on_${h}_writable";
	my $internal_flush  = "_do_${h}_flush";
	my $internal_put    = "_do_${h}_put";
	my $pause_writable  = "_pause_${h}_writable";
	my $resume_writable = "_resume_${h}_writable";

	with 'Reflex::Role::Collectible';

	method_emit_and_stop $cb_error => "error";

	with 'Reflex::Role::Reading' => {
		handle      => $h,
		cb_data     => $p->cb_data(),
		cb_error    => $cb_error,
		cb_closed   => $p->cb_closed(),
		method_read => $method_read,
	};

	with 'Reflex::Role::Readable' => {
		handle      => $h,
		active      => 1,
		cb_ready    => $method_read,
	};

	with 'Reflex::Role::Writing' => {
		handle      => $h,
		cb_error    => $cb_error,
		method_put  => $internal_put,
	};

	method $method_writable => sub {
		my ($self, $arg) = @_;

		my $octets_left = $self->$internal_flush();
		return if $octets_left;

		$self->$pause_writable($arg);
	};

	with 'Reflex::Role::Writable' => {
		handle      => $h,
		cb_ready    => $method_writable,
		method_pause => $pause_writable,
	};

	# Multiplex a single stop() to the sub-roles.
	method $p->method_stop() => sub {
		my $self = shift;
		$self->stop_handle_readable();
		$self->stop_handle_writable();
	};

	method $method_put => sub {
		my ($self, $arg) = @_;
		my $flush_status = $self->$internal_put($arg);
		return unless $flush_status;
		$self->$resume_writable(), return if $flush_status == 1;
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

Please see L<Reflex::Role::Reading/cb_closed>.
Reflex::Role::Reading's "cb_closed" defines this callback.

=head3 cb_data

Please see L<Reflex::Role::Reading/cb_data>.
Reflex::Role::Reading's "cb_data" defines this callback.

=head3 cb_error

Please see L<Reflex::Role::Reading/cb_error>.
Reflex::Role::Reading's "cb_error" defines this callback.

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
