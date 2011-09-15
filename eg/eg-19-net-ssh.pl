#!/usr/bin/perl
# vim: ts=2 sw=2 noexpandtab

# Demonstrate Runner.pm used with other open3-like things.

use warnings;
use strict;
use lib qw(../lib);

use Runner;

my $cmd = q(
	perl -MTime::HiRes=sleep -wle '
		$| = 1;
		for (1..3) { $_ = qq[pid($$) moo($_)]; print; warn "$_\n"; sleep rand; }
	'
);

sub my_start {
	my ($host, $cmd) = @_;

	use Net::SSH qw(sshopen3);
	use Symbol qw(gensym);

	my ($fh_in, $fh_out, $fh_err) = (gensym(), gensym(), gensym());

	my $pid = sshopen3($host, $fh_in, $fh_out, $fh_err, $cmd);

	return($pid, $fh_in, $fh_out, $fh_err);
}

my $runner_1;
{
	my ($pid, $fh_in, $fh_out, $fh_err) = my_start('remote.example.com', $cmd);

	$runner_1 = Runner->new(
		stdin   => $fh_in,
		stdout  => $fh_out,
		stderr  => $fh_err,
		pid     => $pid,

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

my $runner_2;
{
	my ($pid, $fh_in, $fh_out, $fh_err) = my_start('remote.example.com', $cmd);

	$runner_2 = Runner->new(
		stdin   => $fh_in,
		stdout  => $fh_out,
		stderr  => $fh_err,
		pid     => $pid,

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
