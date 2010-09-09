{
	package Runner;
	use Moose;
	extends 'Reflex::Base';
	use Reflex::POE::Wheel::Run;
	use Reflex::Callbacks qw(cb_role);

	use constant VERBOSE => 0;

	has count => (
		is => 'rw',
		isa => 'ScalarRef',
	);
	
	has wheel => (
		isa => 'Reflex::POE::Wheel::Run|Undef',
		is  => 'rw',
	);

	has end => (
		isa => 'Int',
		is  => 'ro',
	);

	sub BUILD {
		my $self = shift;

		$self->wheel(
			Reflex::POE::Wheel::Run->new(
				Program => "$^X -wle 'print qq[pid(\$\$) moo(\$_)] for 1..".$self->end."; exit'",
				cb_role($self, "child"),
			)
		);
	}

	sub on_child_stdin {
		VERBOSE and Test::More::diag("stdin flushed");
	}

	sub on_child_stdout {
		my ($self, $args) = @_;
		VERBOSE and Test::More::diag("stdout: $args->{output}");
		${$self->count()}++;
	}

	sub on_child_stderr {
		my ($self, $args) = @_;
		VERBOSE and Test::More::diag("stderr: $args->{output}");
	}

	sub on_child_error {
		my ($self, $args) = @_;
		return if $args->{operation} eq "read";
		VERBOSE and Test::More::diag(
			"$args->{operation} error $args->{errnum}: $args->{errstr}"
		);
	}

	sub on_child_close {
		my ($self, $args) = @_;
		VERBOSE and Test::More::diag("child closed all output");
	}

	sub on_child_signal {
		my ($self, $args) = @_;
		VERBOSE and Test::More::diag("child $args->{pid} exited: $args->{exit}");
		$self->wheel(undef);
	}
}

# Main.

use Test::More tests => 2;

{
	my ($end, $count) = (1, 0);
	my $runner = Runner->new(end => 1, count => \$count);
	Reflex->run_all();
	is($end, $count, "first run ran to completion");
}

{
	my ($end, $count) = (10, 0);
	my $runner2 = Runner->new(end => 10, count => \$count);
	Reflex->run_all();
	Reflex->run_all();
	is($end, $count, "second run ran to completion");
}

exit;
