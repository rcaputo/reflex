package WheelRun;
use Moose;
extends 'Wheel';
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

use SignalChild;
has sigchild_watcher => (
	isa => 'SignalChild|Undef',
	is  => 'rw',
);

sub BUILD {
	my $self = shift;

	$self->sigchild_watcher(
		SignalChild->new(
			pid => $self->wheel()->PID(),
			observers => [
				{
					observer => $self,
					role     => 'sigchld',
				},
			],
		)
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

1;
