# Generic filehandle watcher.

package Reflex::Handle;

use Moose;
extends 'Reflex::Base';
use Scalar::Util qw(weaken);

has handle => (
	isa => 'Maybe[FileHandle]',
	is  => 'rw',
	# TODO - On change, stop the old handle and start the new one.
	# TODO - On clear, stop the old handle.
);

has rd => (
	isa         => 'Bool',
	is          => 'rw',
	trigger     => \&_changed_rd,
);

has wr => (
	isa         => 'Bool',
	is          => 'rw',
	trigger     => \&_changed_wr,
);

has ex => (
	isa         => 'Bool',
	is          => 'rw',
	trigger     => \&_changed_ex,
);

sub BUILD {
	my $self = shift;
	$self->_start();
}

sub _start {
	my $self = shift;
	return unless $self->call_gate("_start");

	# TODO - Repeated code between this and the _changed_rd() etc.
	# methods.  Repeating code is bad, but it's more efficient.  Is
	# there an efficient way to avoid the repetition?

	my $envelope = [ $self ];
	weaken $envelope->[0];

	$POE::Kernel::poe_kernel->select_read(
		$self->handle(), 'select_ready', $envelope, 'readable'
	) if $self->rd();

	$POE::Kernel::poe_kernel->select_write(
		$self->handle(), 'select_ready', $envelope, 'writable'
	) if $self->wr();

	$POE::Kernel::poe_kernel->select_expedite(
		$self->handle(), 'select_ready', $envelope, 'exception'
	) if $self->ex();
}

sub _changed_rd {
	my ($self, $value) = @_;
	return unless $self->call_gate("_changed_rd", $value);
	if ($value) {
		my $envelope = [ $self ];
		weaken $envelope->[0];
		$POE::Kernel::poe_kernel->select_read(
			$self->handle(), 'select_ready', $envelope, 'readable'
		);
	}
	else {
		$POE::Kernel::poe_kernel->select_read($self->handle(), undef);
	}
}

sub _changed_wr {
	my ($self, $value) = @_;
	return unless $self->call_gate("_changed_wr", $value);
	if ($value) {
		my $envelope = [ $self ];
		weaken $envelope->[0];
		$POE::Kernel::poe_kernel->select_write(
			$self->handle(), 'select_ready', $envelope, 'writable'
		);
	}
	else {
		$POE::Kernel::poe_kernel->select_write($self->handle(), undef);
	}
}

sub _changed_ex {
	my ($self, $value) = @_;
	return unless $self->call_gate("_changed_ex", $value);
	if ($value) {
		my $envelope = [ $self ];
		weaken $envelope->[0];
		$POE::Kernel::poe_kernel->select_expedite(
			$self->handle(), 'select_ready', $envelope, 'exception'
		);
	}
	else {
		$POE::Kernel::poe_kernel->select_expedite($self->handle(), undef);
	}
}

sub stop {
	my $self = shift;

	$self->rd(0) if $self->rd();
	$self->wr(0) if $self->wr();
	$self->ex(0) if $self->ex();

	$self->handle(undef);
}

# Part of the POE/Reflex contract.
sub deliver {
	my ($self, $handle, $mode) = @_;
	$self->emit(
		event => $mode,
		args => {
			handle => $handle,
		}
	);
}

sub DEMOLISH {
	my $self = shift;
	$self->stop();
}

no Moose;

1;

__END__

=head1 NAME

Reflex::Handle - Watch a filehandle for read- and/or writability.

=head1 SYNOPSIS

	package Reflex::Listener;
	use Moose;
	extends 'Reflex::Handle';

	has '+rd' => ( default => 1 );

	sub on_handle_readable {
		my ($self, $args) = @_;

		my $peer = accept(my ($socket), $args->{handle});
		if ($peer) {
			$self->emit(
				event => "accepted",
				args  => {
					peer    => $peer,
					socket  => $socket,
				}
			);
			return;
		}

		$self->emit(
			event => "failure",
			args  => {
				peer    => undef,
				socket  => undef,
				errnum  => ($!+0),
				errstr  => "$!",
				errfun  => "accept",
			},
		);
	}

	1;

=head1 DESCRIPTION

Reflex::Handle is scheduled to be deprecated.
Please see Reflex::Role::Readable and Reflex::Role::Writable, which
allow the creation of read- and write-only classes.
Your ideas and feedback for Reflex::Handle's replacement are welcome.

Reflex::Handle watches a filehandle and emits events when it has data
to be read, is ready to be written upon, or has some exceptional
condition to be addressed.

As with most Reflex objects, Reflex::Handle may be composed by
subclassing (is-a) or by containership (has-a).

=head2 Attributes

Reflex::Handle has a few attributes that control its behavior.  These
attributes may be specified during construction.  They may also be
changed while the object runs through methods of the same name.

=head3 handle

Reflex::Handle's "handle" should contain a Perl file handle to watch.

	my $socket = IO::Socket::INET->new(
		LocalAddr => '127.0.0.1',
		LocalPort => 12345,
		Listen    => 5,
		Reuse     => 1,
	);

	my $handle = Reflex::Handle->new( handle => $socket );

However a Reflex::Handle won't emit events without also enabling one
or more of "rd", "wr", or "ex".

=head3 rd

The "rd" attribute is a Boolean that controls whether Reflex::Handle
watches "handle" for readability.  Reflex::Handle emits "readable"
events when handles contain data ready to be received.

	my $handle = Reflex::Handle->new(
		handle      => $socket,
		rd          => 1,
		on_readable => cb_coderef(\&read_from_it),
	);

It may also be modified at run time to enable or disable readability
watching as needed.

	$handle->rd(0);  # Done reading.

=head3 wr

The "wr" attribute enables or disables watching for writability on the
"handle" attribute.  Its semantics and usage are otherwise identical
to those of "rd".

Reflex::Handle emits "writable" events when underlying file handles
have buffer space for new output.  For example, when a socket has
successfully written data to the network and has capacity to buffer
more data.

=head3 ex

The "wr" attribute enables or disables watching for exceptions on the
"handle" attribute.  Exceptions include errors and out-of-band
notifications.  Its semantics and usage are otherwise identical to
those of "rd".

Reflex::Handle emits "exception" events when "ex" is enabled and some
exceptional occurrence happens.

=head2 Methods

=head3 stop

Reflex::Handle's stop() method disables all watching and clears the
file handle held within the object.  stop() will be called implicitly
if the Reflex::Handle object is destroyed.

If the program is holding no other reference to the watched file, then
Perl will close the file after the Reflex::Handle object is stopped.

	sub on_handle_error {
		my $self = shift;
		$self->handle()->stop();
	}

=head1 EXAMPLES

L<Reflex::Listener> extends Reflex::Handle to listen for connections
on a server socket.

L<Reflex::Connector> extends Reflex::Handle to wait for non-blocking
client sockets to fully connect.

L<Reflex::Stream> extends Reflex::Handle to read data when it's ready
and write data when it can.

L<Reflex::Role::UdpPeer> extends Reflex::Handle to read UDP packets
when they arrive on a socket.

=head1 SEE ALSO

L<Moose::Manual::Concepts>

L<Reflex>

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
