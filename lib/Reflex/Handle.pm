# Generic filehandle watcher.

package Reflex::Handle;

use Moose;
extends 'Reflex::Object';
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
	$self->start();
}

sub start {
	my $self = shift;
	return unless $self->call_gate("start");

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

1;
# TODO - Document.

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

Reflex::Handle watches a filehandle and emits events when it has data
to be read, is ready to be written upon, or has some exceptional
condition to be addressed.

As with most Reflex objects, Reflex::Handle may be composed by
subclassing (is-a) or by containership (has-a).

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
