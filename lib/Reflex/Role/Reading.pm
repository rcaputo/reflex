package Reflex::Role::Reading;
# vim: ts=2 sw=2 noexpandtab

use Reflex::Role;

use Reflex::Event::Octets;
use Reflex::Event::EOF;
use Reflex::Event::Error;

# The method_read parameter matches Reflex::Role::Readable's default
# callback.
# TODO - Any way we can coordinate this so it's obvious in the code
# but not too verbose?

attribute_parameter att_handle  => "handle";
callback_parameter  cb_closed   => qw( on att_handle closed );
callback_parameter  cb_data     => qw( on att_handle data );
callback_parameter  cb_error    => qw( on att_handle error );
method_parameter    method_read => qw( read att_handle _ );

role {
	my $p = shift;

	my $att_handle  = $p->att_handle();
	my $cb_closed   = $p->cb_closed();
	my $cb_data     = $p->cb_data();
	my $cb_error    = $p->cb_error();
	my $method_read = $p->method_read();

	requires $att_handle, $cb_closed, $cb_data, $cb_error;

	method $method_read => sub {
		my ($self, $event) = @_;

		# TODO - Hardcoding this at 65536 isn't very flexible.
		my $octet_count = sysread($event->handle(), my $buffer = "", 65536);

		# Got data.
		if ($octet_count) {
			$self->$cb_data(
				Reflex::Event::Octets->new( _emitters => [ $self ], octets => $buffer )
			);
			return $octet_count;
		}

		# EOF
		if (defined $octet_count) {
			$self->$cb_closed(Reflex::Event::EOF->new( _emitters => [ $self ]));
			return $octet_count;
		}

		# Quelle erreur!
		$self->$cb_error(
			Reflex::Event::Error->new(
				_emitters => $self,
				number    => ($! + 0),
				string    => "$!",
				function  => "sysread",
			)
		);

		return; # Nothing.
	};
};

1;

__END__

=head1 NAME

Reflex::Role::Reading - add standard sysread() behavior to a class

=head1 SYNOPSIS

TODO - Changed again.

	package InputStreaming;
	use Reflex::Role;

	attribute_parameter handle      => "handle";
	callback_parameter  cb_data     => qw( on handle data );
	callback_parameter  cb_error    => qw( on handle error );
	callback_parameter  cb_closed   => qw( on handle closed );
	method_parameter    method_stop => qw( stop handle _ );

	role {
		my $p = shift;

		my $h           = $p->handle();
		my $cb_error    = $p->cb_error();
		my $method_read = "on_${h}_readable";

		method-emit_and_stop $cb_error => $p->ev_error();
TODO - Changed.
		with 'Reflex::Role::Reading' => {
			handle      => $h,
			cb_data     => $p->cb_data(),
			cb_error    => $cb_error,
			cb_closed   => $p->cb_closed(),
			method_read => $method_read,
		};

		with 'Reflex::Role::Readable' => {
			handle      => $h,
			cb_ready    => $method_read,
			method_stop => $p->method_stop(),
		};
	};

	1;

=head1 DESCRIPTION

Reflex::Role::Readable implements a standard nonblocking sysread()
feature so that it may be added to classes as needed.

There's a lot going on in the SYNOPSIS.

Reflex::Role::Reading is consumed to read from the InputStreaming
handle.  The method named in $method_read is generated to read from
the handle.  Three callbacks may be triggered depending on the status
returned by sysread().  The "cb_data" callback will be invoked when
data is read from the stream.  "cb_error" will be called if there's a
sysread() error.  "cb_closed" will be triggered if the stream closes
normally.

Reflex::Role::Readable is consumed to watch the handle for activity.
Its "cb_ready" is invoked whenever the handle has data to be read.
"cb_ready" is Reflex::Role::Reading's "method_read", so data is read
when it's ready.

=head2 Attribute Role Parameters

=head3 handle

C<handle> names an attribute holding the handle to be watched for
readable data.

=head2 Callback Role Parameters

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

=head2 Method Role Parameters

=head3 method_read

This role genrates a method to read from the handle in the attribute
named in its "handle" role parameter.  The "method_read" role
parameter defines the name for this generated read method.  By
default, the read method is named after tha handle's attribute:
"read_${$handle_name}".

=head1 EXAMPLES

TODO - I'm sure there are some.

=head1 SEE ALSO

L<Reflex>
L<Reflex::Role>
L<Reflex::Role::Writing>
L<Reflex::Role::Readable>
L<Reflex::Role::Streaming>

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
