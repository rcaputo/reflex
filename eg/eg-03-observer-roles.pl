#!/usr/bin/env perl

# Reflex supports "role-based" callbacks where events are mapped to
# handlers through a handler naming convention.  The cb_role()
# callback constructor assigns a role to an event emitter.  Methods
# beginning with "on_${role}" in the watcher object are used to handle
# the emitter's events.
#
# In this test case, the Reflex::Interval object is assigned the role
# "waitron".  It emits "tick" events that are handled by the watcher's
# on_waitron_tick() method.
#
# An object may watch another in more than one role.  In this test
# case, the Reflex::Interval is also watched in the "waitroff" role.
# The on_waitroff_tick() method is also invoked.

use warnings;
use strict;
use lib qw(../lib);

use Test::More tests => 10;

### Define a class to watch events from a Reflex::Interval.

{
	package Watcher;

	use Moose;
	extends 'Reflex::Base';

	use Reflex::Interval;
	use Reflex::Callbacks qw(cb_role);

	use Test::More;

	has timer => (
		isa => 'Maybe[Reflex::Interval]',
		is  => 'rw',
	);

	sub BUILD {
		my $self = $_[0];

		$self->timer(
			Reflex::Interval->new(
				interval    => 0.1,
				auto_repeat => 1,
				cb_role($self, "waitron"),
			),
		);
		ok( (defined $self->timer()), "started timer object in waitron role" );

		# It's possible to mix and match.
		pass("also watching timer as the waitroff role");
		$self->watch($self->timer() => cb_role($self, "waitroff"));
	}

	my $countdown = 3;
	sub on_waitron_tick {
		my $self = shift;

		pass("on_waitron_tick invoked");
		$self->timer(undef) unless --$countdown;
	}

	sub on_waitroff_tick {
		pass("on_waitroff_tick called back");
	}
}

### Main.

# Watchers must not go out of scope.  They stop watching if they do.
my $watcher = Watcher->new();
ok( (defined $watcher), "started watcher object" );

Reflex->run_all();
pass("run_all() returned");

exit;
