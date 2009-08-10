# Generic filehandle watcher.

package Handle;

use Moose;
extends 'Stage';

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

	my @selects;
	push @selects, [ 'read',     $self->handle() ] if $self->rd();
	push @selects, [ 'write',    $self->handle() ] if $self->wr();
	push @selects, [ 'expedite', $self->handle() ] if $self->ex();

	if (@selects) {
		$POE::Kernel::poe_kernel->call(
			$self->session_id(),
			'select_on',
			$self,
			@selects
		);
	}
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

	my @selects;
	push @selects, [ 'read',     $self->handle() ] if $self->rd();
	push @selects, [ 'write',    $self->handle() ] if $self->wr();
	push @selects, [ 'expedite', $self->handle() ] if $self->ex();

	if (@selects) {
		$POE::Kernel::poe_kernel->call(
			$self->session_id(),
			'select_off',
			@selects
		);
	}
}

1;
