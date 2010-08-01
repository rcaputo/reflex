package Reflex::Role::Writing;
use Reflex::Role;

attribute_parameter handle        => "handle";
method_parameter    method_put    => qw( put handle _ );
method_parameter    method_flush  => qw( flush handle _ );
callback_parameter  cb_error      => qw( on handle error );

role {
	my $p = shift;

	my $h             = $p->handle();
	my $cb_error      = $p->cb_error();
	my $method_flush  = $p->method_flush();

	requires $cb_error;

	has out_buffer => (
		is      => 'rw',
		isa     => 'ScalarRef',
		default => sub { my $x = ""; \$x },
	);

	method $method_flush => sub {
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
		return length $$out_buffer;
	};

	method $p->method_put() => sub {
		my ($self, @chunks) = @_;

		# TODO - Benchmark string vs. array buffering.

		use bytes;

		my $out_buffer = $self->out_buffer();
		if (length $$out_buffer) {
			$$out_buffer .= $_ foreach @chunks;
			return 2;
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

			return 1;
		}

		# Flushed it all.  Yay!
		return 0;
	};
};

1;

__END__

=head1 NAME

Reflex::Role::Writing - add buffered non-blocking syswrite() to a class

=head1 SYNOPSIS

	package OutputStreaming;
	use Reflex::Role;

	attribute_parameter handle       => "handle";
	callback_parameter  cb_error     => qw( on handle error );
	method_parameter    method_put   => qw( put handle _ );
	method_parameter    method_stop  => qw( stop handle _ );
	method_parameter    method_flush => qw( _flush handle writable );

	role {
		my $p = shift;

		my $h         = $p->handle();
		my $cb_error  = $p->cb_error();

		with 'Reflex::Role::Writing' => {
			handle        => $h,
			cb_error      => $p->cb_error(),
			method_put    => $p->method_put(),
			method_flush  => $p->method_flush(),
		};

		with 'Reflex::Role::Writable' => {
			handle        => $h,
			cb_ready      => $p->method_flush(),
		};

=head1 DESCRIPTION

Reflex::Role::Readable implements a standard nonblocking sysread()
feature so that it may be added to classes as needed.

There's a lot going on in the SYNOPSIS.

Reflex::Role::Writing defines methods that will perform non-blocking,
buffered syswrite() on a named "handle".  It has a single callback,
"cb_error", that is invoked if syswrite() ever returns an error.  It
defines a method, "method_put", that is used to write new data to the
handle---or buffer data if it can't be written immediately.
"method_flush" is defined to flush buffered data when possible.

Reflex::Role::Writable implements the other side of the
Writable/Writing contract.  It wastches a "handle" and invokes
"cb_ready" whenever the opportunity to write new data arises.  It
defines a few methods, two of which allow the watcher to be paused and
resumed.

The Writable and Writing roles are generally complementary.  Their
defaults allow them to fit together more succinctly than (and less
understandably than) shown in the SYNOPSIS.

=head2 Attribute Role Parameters

=head3 handle

C<handle> names an attribute holding the handle to be watched for
writable readiness.

=head2 Callback Role Parameters

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

=head3 method_put

This role genrates a method to write data to the handle in the
"handle" attribute.  The "method_put" role parameter specifies the
name of this generated method.  The method's name will be
"put_${handle_name}" by default.

The generated method will immediately attempt to write data if the
role's buffer is empty.  If the buffer contains data, however, then
the new data will be appended there to maintain the ordering of data
in the stream.  Any data that could not be written during "method_put"
will be added to the buffer as well.

The "method_put" implementation will call "method_resume_writable" to
enable background flushing, as needed.

The generated "method_put" will return a numeric code representing the
current state of the role's output buffer.  Undef if syswrite failed,
after "cb_error" has been called.  It returns 0 if the buffer is still
empty after the syswrite().  It returns 1 if the buffer begins to
contain data, or 2 if the buffer already contained data and now holds
more.

The return code is intended to control Reflex::Role::Writable, via
some glue code in the class or role that consumes both.  When
"method_put" returns 1, the consumer should begin triggering
"method_flush" calls on writability callbacks.  The consumer should
stop writability callbacks when "method_flush" returns 0 (no more
octets in the buffer).

=head3 method_flush

This role generates a method to flush data that had to be buffered by
previous "method_put" calls.  It's designed to be used with some kind
of callback system, such as Reflex::Role::Writable's callbacks.

The "method_flush" implementation returns undef on error.  It will
return the number of octets remaining in the buffer, or zero if the
buffer has been completely flushed.

The "method_flush" return value may be used to disable writability
watchers, such as the one provided by Reflex::Role::Writable.  See the
source for Reflex::Role::Streaming for an up-to-date example.

=head1 TODO

There's always something.

=head1 EXAMPLES

Reflex::Role::Streaming is an up-to-date example.

=head1 SEE ALSO

L<Reflex>
L<Reflex::Role>
L<Reflex::Role::Writable>
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
