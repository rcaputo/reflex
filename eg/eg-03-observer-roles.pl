#!/usr/bin/env perl

# An observer's callbacks can be inferred by observation roles and the
# event names that the observed object emits.  In this example, the
# Reflex::Timer object is given the role "waitron".  Its "tick" events
# are routed to the observer's "on_waitron_dig" method.
#
# In addition, the timer is also observed in the waitroff role.  One
# timer may trigger multiple callbacks.

use warnings;
use strict;
use lib qw(../lib);

# Define the watcher class.

{
	package Watcher;
	use Moose;
	extends 'Reflex::Object';
	use Reflex::Timer;
	use ExampleHelpers qw(eg_say);

	has timer => (
		isa => 'Reflex::Timer',
		is  => 'rw',
	);

	sub BUILD {
		my $self = $_[0];

		eg_say("watcher creates a timer with the waitron role");
		$self->timer(
			Reflex::Timer->new(
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
		eg_say("observing timer as the waitroff role, too");
		$self->observe_role(
			observed  => $self->timer(),
			role      => "waitroff",
		);
	}

	sub on_waitron_tick {
		eg_say("on_waitron_tick called back");
	}

	sub on_waitroff_tick {
		eg_say("on_waitroff_tick called back");
	}
}

# Main.

# Watchers must not go out of scope.  They stop watching if they do.
my $watcher = Watcher->new();

Reflex::Object->run_all();
exit;
