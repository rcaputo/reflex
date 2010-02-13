package Reflex::POE::Wheel::Run;
use Moose;
extends 'Reflex::POE::Wheel';
use POE::Wheel::Run;

# These are class methods, returning static class data.
# TODO - How does Moose do this?

sub event_to_index {
	return(
		{
			StdinEvent  => 0,
			StdoutEvent => 1,
			StderrEvent => 2,
			ErrorEvent  => 3,
			CloseEvent  => 4,
		},
	);
}

sub event_emit_names {
	return(
		[
			'stdin',  # StdinEvent
			'stdout', # StdoutEvent
			'stderr', # StderrEvent
			'error',  # ErrorEvent
			'closed', # ClosedEvent
		],
	);
}

sub event_param_names {
	return(
		[
			# 0 = StdinEvent
			[ "wheel_id" ],

			# 1 = StdoutEvent
			[ "output", "wheel_id" ],

			# 2 = StderrEvent
			[ "output", "wheel_id" ],

			# 3 = ErrorEvent
			[ "operation", "errnum", "errstr", "wheel_id", "handle_name" ],

			# 4 = CloseEvent
			[ "wheel_id" ],
		]
	);
}

sub wheel_class {
	return 'POE::Wheel::Run';
}

sub valid_params {
	return(
		{
			CloseOnCall => 1,
			Conduit => 1,
			Filter => 1,
			Group => 1,
			NoSetPgrp => 1,
			NoSetSid => 1,
			Priority => 1,
			Program => 1,
			ProgramArgs => 1,
			StderrDriver => 1,
			StderrFilter => 1,
			StdinDriver => 1,
			StdinFilter => 1,
			StdioDriver => 1,
			StdioFilter => 1,
			StdoutDriver => 1,
			StdoutFilter => 1,
			User => 1,
		}
	);
}

# Also handle signals.

use Reflex::PID;
has sigchild_watcher => (
	isa    => 'Reflex::PID|Undef',
	is     => 'rw',
	traits => ['Reflex::Trait::Observer'],
	role   => 'sigchld',
);

sub BUILD {
	my $self = shift;

	$self->sigchild_watcher(
		Reflex::PID->new(pid => $self->wheel()->PID())
	);
}

# Rethrow our signal event.
sub on_sigchld_signal {
	my ($self, $args) = @_;
	$self->emit(
		event => 'signal',
		args  => $args,
	);
}

no Moose;
__PACKAGE__->meta()->make_immutable();

1;

__END__

=head1 NAME

Reflex::POE::Wheel::Run - Allow a Reflex class to represent POE::Wheel::Run.

=head1 SYNOPSIS

# Not a complete example.  Please see eg-07-wheel-run.pl or even
# better eg-08-observer-trait.pl for working examples.

	has child => (
		traits  => ['Reflex::Trait::Observer'],
		isa     => 'Reflex::POE::Wheel::Run|Undef',
		is      => 'rw',
	);

	sub BUILD {
		my $self = shift;
		$self->child(
			Reflex::POE::Wheel::Run->new(
				Program => "$^X -wle 'print qq[pid(\$\$) moo(\$_)] for 1..10; exit'",
			)
		);
	}

	sub on_child_stdout {
		my ($self, $args) = @_;
		print "stdout: $args->{output}\n";
	}

	sub on_child_close {
		my ($self, $args) = @_;
		print "child closed all output\n";
	}

	sub on_child_signal {
		my ($self, $args) = @_;
		print "child $args->{pid} exited: $args->{exit}\n";
		$self->child(undef);
	}

TODO - Needs a better example.

=head1 DESCRIPTION

Reflex::POE::Wheel::Run represents an enhanced POE::Wheel::Run object.
Currently, the sole enhancement is to wait for SIGCHLD and notify
observers when the child process exits.

TODO - Further improvement would be to defer the SIGCHLD notification
until all child output has been received.

TODO - Complete the API and documentation.

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
