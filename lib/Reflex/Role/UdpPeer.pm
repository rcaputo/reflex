package Reflex::Role::UdpPeer;
use Moose::Role;
with 'Reflex::Role::Object';
use Reflex::Handle;

has port => (
	isa => 'Int',
	is  => 'ro',
);

has handle => (
	isa     => 'Reflex::Handle|Undef',
	is      => 'rw',
	traits  => ['Reflex::Trait::Observer'],
	role    => 'remote',
);

has max_datagram_size => (
	isa     => 'Int',
	is      => 'rw',
	default => 16384,
);

after 'BUILD' => sub {
	my $self = shift;

	$self->handle(
		Reflex::Handle->new(
			handle => IO::Socket::INET->new(
				Proto     => 'udp',
				LocalPort => $self->port(),
			),
			rd => 1,
		)
	);
	undef;
};

sub on_remote_readable {
	my ($self, $args) = @_;

	my $remote_address = recv(
		$args->{handle},
		my $datagram = "",
		$self->max_datagram_size(),
		0
	);

	$self->emit(
		event => "datagram",
		args => {
			datagram    => $datagram,
			remote_addr => $remote_address,
		},
	);
}

sub send {
	my ($self, @args) = @_;

	my $args = $self->_check_args(
		\@args,
		[ 'datagram', 'remote_addr' ],
		[ ],
	);

	# Success!
	return if send(
		$self->handle()->handle(), # TODO - Ugh!
		$args->{datagram},
		0,
		$args->{remote_addr},
	) == length($args->{datagram});

	$self->emit(
		event => "error",
		args  => {
			errfun  => "send",
			errnum  => $! + 0,
			errstr  => "$!",
		},
	);
}

sub destruct {
	my $self = shift;
	$self->handle(undef);
}

1;

__END__

=head1 NAME

Reflex::Role::UdpPeer - Add non-blocking UDP networking to an object.

=head1 SYNOPSIS

This UDP echo service comes from a more complete program,
eg/eg-06-moose-roles.pl in Reflex's tarball.

	package Reflex::UdpPeer::Echo;
	use Moose;
	with 'Reflex::Role::UdpPeer';

	sub on_udppeer_datagram {
		my ($self, $args) = @_;
		my $data = $args->{datagram};

		if ($data =~ /^\s*shutdown\s*$/) {
			$self->destruct();
			return;
		}

		$self->send(
			datagram    => $data,
			remote_addr => $args->{remote_addr},
		);
	}

	sub on_udppeer_error {
		my ($self, $args) = @_;
		warn "$args->{op} error $args->{errnum}: $args->{errstr}";
		$self->destruct();
	}

	1;

Programs may inherit from Reflex::UdpPeer rather than use the Moose
role directly.

	package UdpEchoPeer;
	use base 'Reflex::UdpPeer';

	...;

	1;

=head1 DESCRIPTION

Reflex::Role::UdpPeer implements non-blocking UDP socket work.  This
isn't very hard, since UDP sockets don't normally block anyway.

=head1 Public Attributes

=head2 port

Reflex::Role::UdpPeer will create a UDP socket during construction.
The socket will be bound to the port (numeric or symbolic name)
specified in the "port" attribute.

This may change in the future.  Reflex really should be letting you
create and provide your own handle, via a "handle" attribute, bound
and otherwise set up how you like it.

=head2 max_datagram_size

"max_datagram_size" sets the limit for recv() calls.  It defaults to
16KB (16384).  This may change in the future.

=head1 Public Methods

=head2 send

Reflex::Role::UdpPeer's send() is a wrapper around Perl's built-in
send() function.  It checks the return value, and it will emit() an
"error" message if send() fails.

This may also change, as the conventions for failure events solidify.
Your feedback will help expedite the solidification.

=head2 destruct

destruct() clears the UDP peer's "handle" attribute and performs other
cleanup to shut down the object.

The name will probably change to stop() or shutdown() as naming
conventions standardize.

=head1 Public Events

=head2 datagram

Reflex::Role::UdpPeer emits "datagram" events when datagrams arrive.
These events include two named values: "datagram" contains the data
returned by recv().  "remote_addr" holds the datagram sender's packed
address.

=head2 error

Reflex::Role::UdpPeer will emit() an "error" event if send() fails.
It follows a standard convention for reporting errors or failures.
Errors include three fields: "errfun" describes the function that
failed, generally "send" or "recv".  "errnum" and "errstr" hold the
numeric and stringified versions of C<$!> at the time of the failure.

Programs should not examine C<$!> directly, as the value of this
global special variable may have changed between the time of failure
and the time of callback.

Reflex generally uses "failure" rather than "error" to indicate
failures.  This "error" event may be renamed later to conform with
that emerging conventino.

=head1 EXAMPLES

eg/eg-04-inheritance.pl inherits from Reflex::UdpPeer.

eg/eg-05-composition.pl uses a Reflex::UdpPeer object as a helper, and
composes with it in a has-a relationship.

eg/eg-06-moose-roles.pl composes an ojbect with Reflex::Role::UdpPeer.

=head1 SEE ALSO

L<Moose::Manual::Concepts>

L<Reflex>
L<Reflex::Object>
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
