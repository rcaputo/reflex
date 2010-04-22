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

1;

__END__

=head1 NAME

Reflex::PID - Observe the exit of a subprocess by its SIGCHLD signal.

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

Reflex::PID waits for a particular child process to exit.  It emits a
"signal" event with information about the child process when it has
detected the child has exited.

Since Reflex::PID waits for a particular process ID, it's pretty much
useless afterwards.  Consider pairing it with Reflex::Collection if
you have to maintain several transient processes.

Reflex::PID extends Reflex::Signal to handle a particular kind of
signal---SIGCHLD.

TODO - However, first we need to make Reflex::PID objects stop
themselves and emit "stopped" events when they're done.  Otherwise
Reflex::Collection won't know when to destroy them.

=head2 Public Events

=head3 signal

Reflex::PID's "signal" event includes two named parameters.  "pid"
contains the process ID that exited.  "exit" contains the process'
exit value---a copy of C<$?> at the time the process exited.  Please
see L<perlvar/"$?"> for more information about that special Perl
variable.

=head1 SEE ALSO

L<Moose::Manual::Concepts>

L<Reflex>
L<Reflex::Signal>
L<Reflex::POE::Wheel::Run>

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
