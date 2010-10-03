#!/usr/bin/perl

# Demonstrate subprocesses without POE::Wheel::Run.
# Test case for upcoming Reflex::Run, which drives IPC::Run.

use warnings;
use strict;
use lib qw(../lib);

use Runner;

my $cmd = [
	$^X, '-MTime::HiRes=sleep', '-wle',
	q($|=1;) .
	q(for (1..3) { $_ = qq[pid($$) moo($_)]; print; warn "$_\n"; sleep rand; })
];

sub my_start {
	my $cmd = shift;

	use IPC::Run qw(start);
	use Symbol qw(gensym);

	my ($fh_in, $fh_out, $fh_err) = (gensym(), gensym(), gensym());

	my $ipc_run = start(
		$cmd,
		'<pipe', $fh_in,
		'>pipe', $fh_out,
		'2>pipe', $fh_err,
	) or die "IPC::Run start() failed: $? ($!)";

	return($ipc_run, $fh_in, $fh_out, $fh_err);
}

my ($ipc_run_1, $runner_1);
{
	($ipc_run_1, my($fh_in, $fh_out, $fh_err)) = my_start($cmd);

	$runner_1 = Runner->new(
		stdin   => $fh_in,
		stdout  => $fh_out,
		stderr  => $fh_err,
		pid     => $ipc_run_1->{KIDS}[0]{PID},

		on_stdout_closed  => sub { print "runner_1 stdout closed\n" },
		on_stderr_closed  => sub { print "runner_1 stderr closed\n" },
		on_stdout_data    => sub { print "runner_1 stdout: $_[1]{data}" },
		on_stderr_data    => sub { print "runner_1 stderr: $_[1]{data}" },

		on_exit   => sub {
			my ($self, $args) = @_;
			warn "runner_1 child $args->{pid} exited: $args->{exit}\n";
			$runner_1 = undef;
		},
	);
}

my ($ipc_run_2, $runner_2);
{
	($ipc_run_2, my($fh_in, $fh_out, $fh_err)) = my_start($cmd);

	$runner_2 = Runner->new(
		stdin   => $fh_in,
		stdout  => $fh_out,
		stderr  => $fh_err,
		pid     => $ipc_run_2->{KIDS}[0]{PID},

		on_stdout_closed  => sub { print "runner_2 stdout closed\n" },
		on_stderr_closed  => sub { print "runner_2 stderr closed\n" },
		on_stdout_data    => sub { print "runner_2 stdout: $_[1]{data}" },
		on_stderr_data    => sub { print "runner_2 stderr: $_[1]{data}" },

		on_exit   => sub {
			my ($self, $args) = @_;
			warn "runner_2 child $args->{pid} exited: $args->{exit}\n";
			$runner_2 = undef;
		},
	);
}

Reflex->run_all();
exit;
