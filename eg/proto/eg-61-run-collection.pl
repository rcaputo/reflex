# vim: ts=2 sw=2 noexpandtab
# This is a quick, one-off implementation of a one-shot worker pool.
# Give it some jobs, and it'll run them all in parallel.  It will
# return results in the order of completion.
#
# It doesn't use the proposed collection promise.
# It doesn't limit simultaneous workers.
# It doesn't implement a generic Enterprise Integration Pattern.
# In short, it does almost nothing generically useful.
#
# It does, however, act as an example of Reflex::POE::Wheel::Run used
# for a practical purpose.

use lib qw(../lib);

# Start a parallel runner with a list of jobs.
# ParallelRunner's implementation is below.

my $pr = ParallelRunner->new(
	jobs => [
		[ \&adder,      1, 2, 3 ],
		[ \&multiplier, 4, 5, 6 ],
	]
);

# Consume results until we're done.

while (my $event = $pr->next()) {
	use YAML;
	print YAML::Dump($event->{arg}{result});
}

exit;

# Jobs to run.

sub adder {
	use Time::HiRes qw(sleep); sleep rand();

	my $accumulator = 0;
	$accumulator += $_ foreach @_;
	return [ adder => $accumulator ];
}

sub multiplier {
	use Time::HiRes qw(sleep); sleep rand();

	my $accumulator = 1;
	$accumulator *= $_ foreach @_;
	return [ multiplier => $accumulator ];
}

# Implementation of the ParallelRunner.

BEGIN {
	package ParallelRunner;

	use Moose;
	extends 'Reflex::Base';
	use Reflex::Collection;
	use Reflex::POE::Wheel::Run;
	use Reflex::Callbacks;

	use POE::Filter::Line;
	use POE::Filter::Reference;

	has jobs => (
		isa => 'ArrayRef[ArrayRef]',
		is  => 'ro',
	);

	has_many workers => ( handles => { remember_worker => "remember" } );

	sub BUILD {
		my ($self, $args) = @_;

		foreach my $job (@{$self->jobs()}) {
			my ($coderef, @parameters) = @$job;

			$self->remember_worker(
				Reflex::POE::Wheel::Run->new(
					Program  => sub {
						my $f = POE::Filter::Reference->new();
						my $output = $f->put( [ $coderef->(@parameters) ] );
						syswrite(STDOUT, $_) foreach @$output;
						close STDOUT;
					},
					StdoutFilter => POE::Filter::Reference->new(),
					cb_role($self, "child"),
				)
			);
		}
	}

	sub on_child_stderr {
		warn "child reported: $_[1]{output}\n";
	}

	sub on_child_stdout {
		my ($self, $args) = @_;

		$self->emit(
			event => 'result',
			args  => { result => $args->{output} },
		);
	}
}
