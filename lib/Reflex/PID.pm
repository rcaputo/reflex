package Reflex::PID;

use Moose;
extends qw(Reflex::Signal);

has '+name' => (
	default => 'CHLD',
);

has 'pid' => (
	isa       => 'Int',
	is        => 'ro',
	required  => 1,
	default   => sub { die "required" },
);

__PACKAGE__->_register_signal_params(qw(pid exit));

sub start_watching {
	my $self = shift;
	return unless $self->call_gate("start_watching");
	$POE::Kernel::poe_kernel->sig_child($self->pid(), "signal_happened");
}

sub stop_watching {
	my $self = shift;
	return unless $self->call_gate("stop_watching");
	$POE::Kernel::poe_kernel->sig_child($self->pid(), undef);
	$self->name(undef);
}

no Moose;
__PACKAGE__->meta()->make_immutable();

1;

__END__

=head1 NAME

Reflex::PID - Observe the exit of a subprocess, via handling SIGCHLD.

=head1 SYNOPSIS

# Not a complete program.  Please see the source for
# Reflex::POE::Wheel::Run for one example.

	use Reflex::PID;

	has sigchild_watcher => (
		isa    => 'Reflex::PID|Undef',
		is     => 'rw',
		traits => ['Reflex::Trait::Observer'],
		role   => 'sigchld',
	);

	sub some_method {
		my $self = shift;

		my $pid = fork();
		die $! unless defined $pid;
		exec("some-program.pl") unless $pid;

		# Parent here.
		$self->sigchild_watcher(
			Reflex::PID->new(pid => $pid)
		);
	}

	sub on_sigchld_signal {
		# Handle the event.
	}

=head1 DESCRIPTION

Reflex::PID waits for a child process to exit, then announces the fact
by emitting a "signal" event.

TODO - Complete the documentation, including the parameters of the
signal event.

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
