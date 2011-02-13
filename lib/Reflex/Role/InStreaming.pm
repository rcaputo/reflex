package Reflex::Role::InStreaming;
use Reflex::Role;

attribute_parameter handle      => "handle";

callback_parameter  cb_data     => qw( on handle data );
callback_parameter  cb_error    => qw( on handle error );
callback_parameter  cb_closed   => qw( on handle closed );

callback_parameter  ev_error    => qw( _ handle error );

method_parameter    method_stop => qw( stop handle _ );

role {
	my $p = shift;

	my $h           = $p->handle();
	my $cb_error    = $p->cb_error();
	my $method_read = "_on_${h}_readable";

	with 'Reflex::Role::Collectible';

	method_emit_and_stop $cb_error => $p->ev_error();

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
		method_stop => $p->method_stop(),
	};
};

1;

__END__

=head1 NAME

Reflex::Role::InStreaming - add streaming input behavior to a class

=head1 SYNOPSIS

	use Moose;

	has socket => ( is => 'rw', isa => 'FileHandle', required => 1 );

	with 'Reflex::Role::InStreaming' => {
		handle    => 'socket',
		cb_data   => 'on_socket_data',    # default
		cb_error  => 'on_socket_error',   # default
		cb_closed => 'on_socket_closed',  # default
	};

	sub on_socket_data {
		my ($self, $arg) = @_;
		print "Socket received data: $arg->{data}\n";
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

Reflex::Role::InStreaming is a Moose parameterized role that adds
asynchronous streaming input behavior to Reflex-based classes.  It
comprises Reflex::Role::Collectible for dynamic composition,
Reflex::Role::Readable for asynchronous input watching, and
Reflex::Role::Reading to perform input.

See Reflex::Stream if you prefer runtime composition with objects, or
you just find Moose syntax difficult to handle.

=head2 Required Role Parameters

=head3 handle

The C<handle> parameter must contain the name of the attribute that
holds a filehandle from which data will be read.  The name indirection
allows the role to generate methods that are unique to the handle.
For example, a handle named "XYZ" would generate these methods by
default:

	cb_closed   => "on_XYZ_closed",
	cb_data     => "on_XYZ_data",
	cb_error    => "on_XYZ_error",
	method_stop => "stop_XYZ",

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

=head3 method_stop

Please see L<Reflex::Role::Readable/method_stop>.
Reflex::Role::Readable's "method_stop" defines this method.

=head1 EXAMPLES

See eg/RunnerRole.pm in the distribution.

=head1 SEE ALSO

L<Reflex>
L<Reflex::Role::Readable>
L<Reflex::Role::Reading>
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
