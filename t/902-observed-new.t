#!/usr/bin/env perl

# This test attaches an event emitter to its watcher at the time the
# emitter is created.  This reverses the construction order seen in
# eg-01-discrete-observer.pl, avoiding the potential race condition
# illustrated there.
#
# This API is less verbose than eg-01-discrete-observer.pl, but it's
# not as concise as it can be.  We'll see more concise APIs later.

use warnings;
use strict;
use lib qw(../lib);

use Reflex::Timer;
use Reflex::Callbacks qw(cb_coderef);

use Test::More tests => 5;

### Create a timer with callbacks.
#
# We don't need a discrete observer since we're not explicitly calling
# observe() on anything.

my $countdown = 3;
my $timer;
$timer = Reflex::Timer->new(
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

Reflex::Object->run_all();
pass("run_all() returned");

exit;
