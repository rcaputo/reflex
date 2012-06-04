package Reflex::Acceptor;
# vim: ts=2 sw=2 noexpandtab

use Moose;
extends 'Reflex::Base';
use Reflex::Callbacks qw(make_emitter make_terminal_emitter);

has listener => ( is => 'rw', isa => 'FileHandle', required => 1);
has active => ( is => 'ro', isa => 'Bool', default => 1 );

with 'Reflex::Role::Accepting' => {
	att_active    => 'active',
	att_listener  => 'listener',
	cb_accept     => make_emitter(on_accept => "accept"),
	cb_error      => make_terminal_emitter(on_error => "error"),
	method_pause  => 'pause',
	method_resume => 'resume',
	method_stop   => 'stop',
};

__PACKAGE__->meta->make_immutable;

1;

__END__

=head1 NAME

Reflex::Acceptor - a non-blocking server (client socket acceptor)

=head1 SYNOPSIS

	package TcpEchoServer;

	use Moose;
	extends 'Reflex::Acceptor';
	use Reflex::Collection;
	use EchoStream;

	has_many clients => ( handles => { remember_client => "remember" } );

	sub on_accept {
		my ($self, $event) = @_;
		$self->remember_client(
			EchoStream->new(
				handle => $event->socket(),
				rd     => 1,
			)
		);
	}

	sub on_error {
		my ($self, $event) = @_;
		warn(
			$event->error_function(),
			" error ", $event->error_number(),
			": ", $event->error_string(),
			"\n"
		);
		$self->stop();
	}

=head1 DESCRIPTION

Reflex::Acceptor takes a listening socket and produces new sockets for
clients that connect to it.  It is almost entirely implemented in
Reflex::Role::Accepting.  That role's documentation contains important
details that won't be covered here.

=head2 Public Attributes

=head3 listener

Reflex::Acceptor defines a single attribute, C<listner>, which should
be set to a listening socket of some kind.  Reflex::Acceptor requires
an externally supplied socket so that the user may specify any and all
applicable socket options.

If necessary, the class may later supply a basic socket by default.

Reflex::Role::Accepting explains C<listener> in more detail.

=head2 Public Methods

=head3 pause

pause() will temporarily stop the server from accepting more clients.
See C<method_pause> in Reflex::Role::Accepting for details.

=head3 resume

resume() will resume a temporarily stopped server so that it may
accept more client connections.  See C<method_resume> in
Reflex::Role::Accepting for details.

=head3 stop

stop() will permanently stop the server from accepting more clients.
See C<method_stop> in Reflex::Role::Accepting for details.

=head2 Callbacks

=head3 on_accept

C<on_accept> is called whenever Perl's built-in accept() function
returns a socket.  Reflex::Role::Accepting explains the data returned
with C<on_accept>.  If necessary, that role will also define a default
C<on_accept> handler that emits an "accept" event.

=head3 on_error

C<on_error> is called whenever Perl's built-in accept() function
returns an error.  Reflex::Role::Accepting explains the data returned
with C<on_error>.  If necessary, that role will also define a default
C<on_error> handler that emits an "error" event.

=head2 Public Events

Reflex::Acceptor emits events related to accepting client connections.
These events are defined by Reflex::Role::Accepting, and they will be
explained there.

=head3 accept

If no C<on_accept> handler is set, then Reflex::Acceptor will emit an
"accept" event for every client connection accepted.
Reflex::Role::Accepting explains this event in more detail.

=head3 error

If no C<on_error> handler is set, then Reflex::Acceptor will emit an
"error" event every time accept() returns an error.
Reflex::Role::Accepting explains this event in more detail.

=head1 EXAMPLES

The SYNOPSIS is an excerpt from eg/eg-34-tcp-server-echo.pl.

=head1 SEE ALSO

L<Reflex>
L<Reflex::Role::Accepting>
L<Reflex::Role::Connecting>
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
