#!/usr/bin/env perl

# An observer's callbacks can be inferred by observation roles and the
# event names that the observed object emits.  In this example, the
# Delay object is given the role "waitron".  Its "tick" events are
# routed to the observer's "on_waitron_dig" method.

use warnings;
use strict;

use Stage;
use Delay;
use ExampleHelpers qw(tell);

# Define the watcher class.

{
	package Watcher;
	use Moose;
	extends 'Stage';
	use ExampleHelpers qw(tell);

	has delay => (
		isa => 'Delay|Int',
		is  => 'rw',
	);

	sub BUILD {
		my $self = $_[0];

		tell("watcher creates a delay with the waitron role");
		$self->delay(
			Delay->new(
				interval => 1,
				auto_repeat => 1,
				observers   => [
					{
						observer  => $self,
						role      => "waitron",
					}
				],
			),
		);

		# It's possible to mix and match.
		tell("observing waitroff role, too");
		$self->observe_role(
			observed  => $self->delay(),
			role      => "waitroff",
		);
	}

	sub on_waitron_tick {
		tell("on_waitron_tick called back");
	}

	sub on_waitroff_tick {
		tell("on_waitroff_tick called back");
	}
}

# Must not go out of scope.
# If the watcher goes out of scope, so does the Delay it's watching.
# If the Delay goes out of scope, its timers are cleared too.

my $watcher_role = Watcher->new();

POE::Kernel->run();
exit;
