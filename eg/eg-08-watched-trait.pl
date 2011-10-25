#!/usr/bin/perl
# vim: ts=2 sw=2 noexpandtab

use warnings;
use strict;
use lib qw(../lib);

# Demonstrate how wheels may be encapsulated in thin,
# configuration-only subclasses.

{
	package Runner;
	use Moose;
	extends 'Reflex::Base';
	use Reflex::POE::Wheel::Run;
	use Reflex::Trait::Watched qw(watches);

	watches child => (
		isa     => 'Maybe[Reflex::POE::Wheel::Run]',
	);

	sub BUILD {
		my $self = shift;
		$self->child(
			Reflex::POE::Wheel::Run->new(
				Program => "$^X -wle '\$|=1; while (<STDIN>) { chomp; print qq[pid(\$\$) moo(\$_)] } exit'",
			)
		);

		$self->child()->put("one", "two", "three", "last");
	}

	sub on_child_stdin {
		print "stdin flushed\n";
	}

	sub on_child_stdout {
		my ($self, $stdout) = @_;
		print "stdout: ", $stdout->octets(), "\n";
		$self->child()->kill() if $stdout->octets() =~ /moo\(last\)/;
	}

	sub on_child_stderr {
		my ($self, $stderr) = @_;
		print "stderr: ", $stderr->octets(), "\n";
	}

	sub on_child_error {
		my ($self, $error) = @_;
		return if $error->function() eq "read";
		print $error->formatted(), "\n";
	}

	sub on_child_close {
		my ($self, $eof) = @_;
		print "child closed all output\n";
	}

	sub on_child_signal {
		my ($self, $child) = @_;
		print "child ", $child->pid(), " exited: ", $child->exit(), "\n";
		$self->child(undef);
	}
}

# Main.

my $runner = Runner->new();
Reflex->run_all();
exit;
