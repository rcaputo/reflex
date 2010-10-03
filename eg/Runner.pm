package Runner;
use Moose;
extends 'Reflex::Base';

has [qw(stdin stdout stderr)] => ( isa => 'FileHandle', is => 'ro' );
has pid                       => ( isa => 'Int', is => 'ro' );

with 'RunnerRole' => {
	stdin   => 'stdin',
	stdout  => 'stdout',
	stderr  => 'stderr',
	pid     => 'pid',
	ev_exit => 'exit',
};

1;
