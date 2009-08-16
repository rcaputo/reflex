# Generic filehandle watcher.

package Handle;

use Moose;
extends 'Stage';
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
