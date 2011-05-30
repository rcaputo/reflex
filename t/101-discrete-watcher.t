#!/usr/bin/env perl
# vim: ts=2 sw=2 noexpandtab

# Reflex APIs are built in layers.  This test exercises Reflex's
# low-level watcher API.  There are much more concise and convenient
# APIs layered atop this one.
#
# The test creates two objects: One to periodically emit events, and
# another to watch for those events.  Receipt of those events is
# verified, as well as natural program exit when all events are done.
#
# While verbose, the watch() syntax allows multiple objects to
# consume events from a single emitter.  Most other event systems only
# allow one event consumer.
#
# In some cases, events can be lost if watch() is called after an
# event emitter is created.  However, this shouldn't happen if the
# emitter and its watcher are created in the same basic block of code.
# Under normal circumstances, events are not dispatched in the middle
# of a basic block of code, so events cannot be lost there.
#
# TODO - Another option is to create an object in a stopped state,
# then start it after watchers have been registered.

use warnings;
use strict;
use lib qw(t/lib);

use Reflex::Base;
use Reflex::Interval;
use Reflex::Callbacks qw(cb_coderef);

use Test::More tests => 6;

### Create a timer.  This timer will be watched for events.

my $timer = Reflex::Interval->new( interval => 0.1, auto_repeat => 1 );
ok( (defined $timer), "started timer object" );

### Create an object to watch the timer.

my $watcher = Reflex::Base->new();
ok( (defined $watcher), "started watcher object" );

### The watcher will now watch the timer for a little while.
#
# The watcher only exists so that watch() may be called.  A better
# example would have "tick" handled by one of Reflex::Base's methods.

my $countdown = 3;
$watcher->watch(
	$timer,
	tick => cb_coderef(
		sub {
			pass("'tick' callback invoked ($countdown)");
			$timer = undef unless --$countdown;
		}
	),
);

### Allow the timer and its watcher to run until they are done.

Reflex->run_all();
pass("run_all() returned");

exit;
