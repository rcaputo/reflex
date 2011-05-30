package Reflex::Role::OutStreaming;
# vim: ts=2 sw=2 noexpandtab

use Reflex::Role;

attribute_parameter att_handle  => "handle";
callback_parameter  cb_error    => qw( on att_handle error );
method_parameter    method_put  => qw( put att_handle _ );
method_parameter    method_stop => qw( stop att_handle _ );

role {
	my $p = shift;

	my $att_handle = $p->att_handle();
	my $cb_error   = $p->cb_error();

	requires $att_handle, $cb_error;

	my $method_put = $p->method_put();

	my $internal_flush  = "_do_${att_handle}_flush";
	my $internal_put    = "_do_${att_handle}_put";
	my $method_writable = "_on_${att_handle}_writable";
	my $pause_writable  = "_pause_${att_handle}_writable";
	my $resume_writable = "_resume_${att_handle}_writable";

	with 'Reflex::Role::Collectible';

	with 'Reflex::Role::Writing' => {
		att_handle   => $att_handle,
		cb_error     => $cb_error,
		method_put   => $internal_put,
		method_flush => $internal_flush,
	};

	method $method_writable => sub {
		my ($self, $arg) = @_;

		my $octets_left = $self->$internal_flush();
		return if $octets_left;

		$self->$pause_writable($arg);
	};

	with 'Reflex::Role::Writable' => {
		att_handle   => $att_handle,
		cb_ready     => $method_writable,
		method_pause => $pause_writable,
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

Reflex::Role::OutStreaming - add streaming input behavior to a class

=head1 SYNOPSIS

	use Moose;

	has socket => ( is => 'rw', isa => 'FileHandle', required => 1 );

	with 'Reflex::Role::OutStreaming' => {
		handle     => 'socket',
		method_put => 'put',
	};

=head1 DESCRIPTION

Reflex::Role::OutStreaming is a Moose parameterized role that adds
non-blocking output behavior to Reflex-based classes.  It comprises
Reflex::Role::Collectible for dynamic composition,
Reflex::Role::Writable for asynchronous output callbacks, and
Reflex::Role::Writing to buffer and flush output when it can.

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
	cb_error    => "on_XYZ_error",
	method_put  => "put_XYZ",

This naming convention allows the role to be used for more than one
handle in the same class.  Each handle will have its own name, and the
mixed in methods associated with them will also be unique.

=head2 Optional Role Parameters

=head3 cb_error

Please see L<Reflex::Role::Writing/cb_error>.
Reflex::Role::Writing's "cb_error" defines this callback.

=head3 method_put

Please see L<Reflex::Role::Writing/method_put>.
Reflex::Role::Writing's "method_put" defines this method.

=head1 EXAMPLES

See eg/RunnerRole.pm in the distribution.

=head1 SEE ALSO

L<Reflex>
L<Reflex::Role::Writable>
L<Reflex::Role::Writing>
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
