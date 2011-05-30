package Runner;
# vim: ts=2 sw=2 noexpandtab

use Moose;
extends 'Reflex::Base';
use Reflex::Callbacks qw(make_emitter make_terminal_emitter);

has [qw(stdin stdout stderr)] => ( isa => 'FileHandle', is => 'ro' );
has pid                       => ( isa => 'Int', is => 'ro' );
has active                    => ( isa => 'Bool', is => 'ro', default => 1 );

with 'RunnerRole' => {
	att_active       => 'active',
	att_pid          => 'pid',
	att_stderr       => 'stderr',
	att_stdin        => 'stdin',
	att_stdout       => 'stdout',
	cb_exit          => make_terminal_emitter(on_exit => "exit"),
	cb_stderr_closed => make_emitter(on_stderr_closed => "stderr_closed"),
	cb_stderr_data   => make_emitter(on_stderr_data   => "stderr_data"),
	cb_stderr_error  => make_emitter(on_stderr_error  => "stderr_error"),
	cb_stdin_error   => make_emitter(on_stdin_error   => "stdin_error"),
	cb_stdout_closed => make_emitter(on_stdout_closed => "stdout_closed"),
	cb_stdout_data   => make_emitter(on_stdout_data   => "stdout_data"),
	cb_stdout_error  => make_emitter(on_stdout_error  => "stdout_error"),
};

1;
