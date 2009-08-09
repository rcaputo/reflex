#!/usr/bin/env perl

use warnings;
use strict;

use Stage;
use Delay;

###
# Use case: Observe another object, already created.

# Create a Delay object that may emit events befoe it can be observed.
# Create an observer, which observes it.
# In this case, all observable objects must be explicitly observed.

my $delay_racy = Delay->new( interval => 1, auto_repeat => 1 );

print "race case watching at ", time(), "\n";

my $watcher_racy = Stage->new();
$watcher_racy->observe(
	observed	=> $delay_racy,
	event			=> "ding",
	callback	=> sub { print "race case: ding at ", time(), "\n" },
);

###
# Use case: Observed object is observed during construction.
#
# One of the new requirements is support for truly concurrent objects.
# The previous use case allows a race condition where the Delay may
# emit an event before an observer can observe it.
#
# Here the observer is created first, and the observation is made
# during the Delay's construction.
#
# TODO - Investigate whether an object may be created in a "stopped"
# state, then started once observers are in place.

my $watcher_verbose = Stage->new( );

print "verbose case watching at ", time(), "\n";

my $delay_verbose = Delay->new(
	interval => 1,
	auto_repeat => 1,
	observers => [
		{
			observer	=> $watcher_verbose,
			event			=> "ding",
			callback	=> sub { print "verbose case: ding at ", time(), "\n" },
		},
	],
);

###
# Use case: Role-based observation.  Delay is created with a role, and
# the observer's methods are chosen by "on_${role}_${event}" name.  In
# this case, one class is waiting for delays.

{
	package Watcher;
	use Moose;
	extends 'Stage';

	has delay => (
		isa => 'Delay|Int',
		is  => 'rw',
	);

	sub BUILD {
		my $self = $_[0];

		$self->delay(
			Delay->new( interval => 1, auto_repeat => 1 )
		);

		print "role case: watching at ", time(), "\n";

		$self->observe_role(
			observed	=> $self->delay(),
			role			=> "waitron",
		);

		# Also, we can watch a thing more than once.

		$self->observe_role(
			observed	=> $self->delay(),
			role			=> "waitroff",
		);
	}

	sub on_waitron_ding {
		print "role case: waitron dinged at ", time(), "\n";
	}

	sub on_waitroff_ding {
		print "role case: waitroff dinged at ", time(), "\n";
	}
}

# Must not go out of scope.
# If the watcher goes out of scope, so does the Delay it's watching.
# If the Delay goes out of scope, its timers are cleared too.

my $watcher_role = Watcher->new();

POE::Kernel->run();
exit;
