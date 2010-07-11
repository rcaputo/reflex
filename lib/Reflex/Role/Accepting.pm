package Reflex::Role::Accepting;
use Reflex::Role;

attribute_parameter listener => "listener";

callback_parameter  cb_accept     => qw( on listener accept );
callback_parameter  cb_error      => qw( on listener error );
method_parameter    method_pause  => qw( pause listener _ );
method_parameter    method_resume => qw( resume listener _ );
method_parameter    method_stop   => qw( stop listener _ );

role {
	my $p = shift;

	my $listener  = $p->listener();
	my $cb_accept = $p->cb_accept();
	my $cb_error  = $p->cb_error();

	method "on_${listener}_readable" => sub {
		my ($self, $args) = @_;

		my $peer = accept(my ($socket), $args->{handle});

		if ($peer) {
			$self->$cb_accept(
				{
					peer    => $peer,
					socket  => $socket,
				}
			);
			return;
		}

		$self->$cb_error(
			{
				errnum => ($! + 0),
				errstr => "$!",
				errfun => "accept",
			}
		);

		# TODO - Stop accepting connections?

		return;
	};

	method_emit $cb_accept  => "accept";
	method_emit $cb_error   => "error";   # TODO - Retryable ones.

	with 'Reflex::Role::Readable' => {
		handle        => $listener,
		active        => 1,
		method_pause  => $p->method_pause(),
		method_resume => $p->method_resume(),
		method_stop   => $p->method_stop(),
	};

};

1;

__END__

=head1 NAME

Reflex::Role::Accepting - add connection accepting to a class

=head1 SYNOPSIS

	package Reflex::Acceptor;

	use Moose;
	extends 'Reflex::Base';

	has listener => (
		is        => 'rw',
		isa       => 'FileHandle',
		required  => 1
	);

	with 'Reflex::Role::Accepting' => {
		listener      => 'listener',
		cb_accept     => 'on_accept',
		cb_error      => 'on_error',
		method_pause  => 'pause',
		method_resume => 'resume',
		method_stop   => 'stop',
	};

	1;

=head1 DESCRIPTION

Reflex::Role::Accepting is a Moose parameterized role that adds
accept() reactions to classes that contain listening sockets.  Because
it's a role, the class composition happens before runtime, as opposed
to runtime composition that occurs in other reactive libraries.

See Reflex::Acceptor if you prefer runtime composition with objects,
or if Moose syntax just gives you the heebie-jeebies.

=head2 Required Role Parameters

=head3 listener

The C<listener> parameter must contain the name of an attribute that
contains the listening socket handle.  The name indirection allows the
role to generate methods that are unique to the listening socket.
This becomes important when a class wants to listen on more than one
socket---each socket gets its own name, and distinct methods to tell
them apart.

For example, a listener named "XYZ" would generate these methods by
default:

	cb_accept     => "on_XYZ_accept",
	cb_error      => "on_XYZ_error",
	method_pause  => "pause_XYZ",
	# ... and so on.

=head2 Optional Role Parameters

=head3 cb_accept

C<cb_accept> overrides the default name for the class's accept handler
method.  This handler will be called whenever a client connection is
successfully accepted.

The default method name is "on_${listener}_accept", where $listener is
the name of the listening socket attribute.  This role defines a
default callback that emits an "accept" event.

All callback methods receive two parameters: $self and an anonymous
hash containing information specific to the callback.  In
C<cb_accept>'s case, the anonymous hash contains two values:
accept()'s return value is named "peer", and the accepted client
socket is named "socket".

See perldoc -f accept() for more information about "peer" and
"socket".

=head3 cb_error

C<cb_error> names the $self method that will be called whenever
accept() encounters an error.  By default, this method will be the
catenation of "on_", the C<listener> name, and "_error".  As in
on_XYZ_error(), if the listener is named "XYZ".  The role defines a
default callback that will emit an "error" event with cb_error()'s
parameters.

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

=head3 method_pause

C<method_pause> defines the name of a method that will temporarily
pause the class from accepting new clients.  The role will define this
method for you.  The default method name is "pause_${listener}", where
$listener is the name of the listening socket attribute.

=head3 method_resume

C<method_resume> defines the name of a method that will allow the class
to resume accepting new client connections.  The role will define this
method for you.  The default method name is "resume_${listener}", where
$listener is the name of the listening socket attribute.

=head3 method_stop

C<method_stop> defines the name of a method that will permanently stop
the class from accepting new clients.  The role will define this
method for you.  The default method name is "stop_${listener}", where
$listener is the name of the listening socket attribute.

=head1 EXAMPLES

TODO - I'm sure there are some.

=head1 SEE ALSO

L<Reflex>
L<Reflex::Role::Connecting>
L<Reflex::Acceptor>
L<Reflex::Connector>

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
