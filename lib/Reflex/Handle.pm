# Generic filehandle watcher.

package Reflex::Handle;

use Moose;
extends 'Reflex::Object';
use Scalar::Util qw(weaken);

has handle => (
	isa => 'IO::Handle',
	is  => 'rw',
);

has rd => (
	isa => 'Bool',
	is  => 'rw',
	# TODO - On set, change the handle's watcher state.
);

has wr => (
	isa => 'Bool',
	is  => 'rw',
	# TODO - On set, change the handle's watcher state.
);

has ex => (
	isa => 'Bool',
	is  => 'rw',
	# TODO - On set, change the handle's watcher state.
);

sub BUILD {
	my $self = shift;
	$self->start();
}

sub start {
	my $self = shift;
	return unless $self->call_gate("start");

	my $envelope = [ $self ];
	weaken $envelope->[0];

	$POE::Kernel::poe_kernel->select_read(
		$self->handle(), 'select_ready', $envelope, 'read'
	) if $self->rd();

	$POE::Kernel::poe_kernel->select_write(
		$self->handle(), 'select_ready', $envelope, 'write'
	) if $self->wr();

	$POE::Kernel::poe_kernel->select_expedite(
		$self->handle(), 'select_ready', $envelope, 'expedite'
	) if $self->ex();
}

sub stop {
	my $self = shift;
	return unless $self->call_gate("stop");

	$POE::Kernel::poe_kernel->select_read($self->handle(), undef) if $self->rd();
	$POE::Kernel::poe_kernel->select_write($self->handle(), undef) if $self->wr();
	$POE::Kernel::poe_kernel->select_expedite($self->handle(), undef) if $self->ex();
}

sub _deliver {
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
__PACKAGE__->meta()->make_immutable();

1;

__END__

=head1 NAME

Reflex::Handle - Base class for reactive filehandle objects.

=head1 SYNOPSIS

# Not a complete program.  See Reflex::Role::UdpPeer source, or
# eg-15-handle.pl in the examples.

	has handle => (
		isa     => 'Reflex::Handle|Undef',
		is      => 'rw',
		traits  => ['Reflex::Trait::Observer'],
		role    => 'remote',
	);

	$self->handle(
		Reflex::Handle->new(
			handle => IO::Socket::INET->new(
				Proto     => 'udp',
				LocalPort => $self->port(),
			),
			rd => 1,
		)
	);

	sub on_remote_read {
		my ($self, $args) = @_;

		my $remote_address = recv(
			$args->{handle}, my $datagram = "", 16384, 0
		);

		send(
			$args->{handle}, $datagram, 0, $remote_address
		);
	}

=head1 DESCRIPTION

B<This is early release code.  Please contact us to discuss the API.>

Reflex::Handle watches a filehandle and emits events when it has data
to be read, is ready to be written upon, or has some exceptional
condition to be addressed.

TODO - Complete the documentation.

=head1 GETTING HELP

L<Reflex/GETTING HELP>

=head1 ACKNOWLEDGEMENTS

L<Reflex/ACKNOWLEDGEMENTS>

=head1 SEE ALSO

L<Reflex> and L<Reflex/SEE ALSO>

=head1 BUGS

L<Reflex/BUGS>

=head1 CORE AUTHORS

L<Reflex/CORE AUTHORS>

=head1 OTHER CONTRIBUTORS

L<Reflex/OTHER CONTRIBUTORS>

=head1 COPYRIGHT AND LICENSE

L<Reflex/COPYRIGHT AND LICENSE>

=cut
