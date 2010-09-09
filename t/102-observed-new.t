#!/usr/bin/env perl

# This test attaches an event emitter to its watcher at the time the
# emitter is created.  This is more concise than discrete watch()
# calls, and it can be combined with watch() to support multiple
# event consumers per emitter.
#
# Moose provides opportunities for more concise APIs, as we'll see.

use warnings;
use strict;
use lib qw(t/lib);

use Reflex::Interval;
use Reflex::Callbacks qw(cb_coderef);

use Test::More tests => 5;

### Create a timer with callbacks.
#
# We don't need a discrete watcher since we're not explicitly calling
# watch() on anything.

my $countdown = 3;
my $timer;
$timer = Reflex::Interval->new(
	interval    => 0.1,
	auto_repeat => 1,
	on_tick     => cb_coderef(
		sub {
			pass("'tick' callback invoked ($countdown)");
			$timer = undef unless --$countdown;
		}
	),
);
ok( (defined $timer), "started timer object" );

### Allow the timer and its watcher to run until they are done.

Reflex->run_all();
pass("run_all() returned");

exit;
