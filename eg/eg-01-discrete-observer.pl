#!/usr/bin/env perl

# Reflex APIs are built in layers.  This test exercises Reflex's
# low-level watcher API.  There are much more concise and convenient
# APIs layered atop this one.
#
# The test creates two objects: One to periodically emit events, and
# another to watch for those events.  Receipt of those events is
# verified, as well as natural program exit when all events are done.
#
# Important note: Creating an event emitter before its watcher can
# produce race conditions.  It's better to create the watcher first,
# then attach the event source as part of the source's creation.  See
# eg-02-observed-new.pl for an example.
#
# TODO - Another option is to create an object in a stopped state,
# then start it after watchers have been registered.

use warnings;
use strict;
use lib qw(../lib);

use Reflex::Object;
use Reflex::Timer;
use Reflex::Callbacks qw(cb_coderef);
use TestHelpers qw(test_diag);

use Test::More tests => 6;

### Create a timer.  This timer will be watched for events.

my $timer = Reflex::Timer->new( interval => 0.1, auto_repeat => 1 );
ok( (defined $timer), "started timer object" );

### Create an object to watch the timer.

my $watcher = Reflex::Object->new();
ok( (defined $watcher), "started watcher object" );

### The watcher will now watch the timer for a little while.

my $countdown = 3;
$watcher->observe(
	$timer,
	tick => cb_coderef(
		sub {
			pass("watcher sees 'tick' event");
			$timer = undef unless --$countdown;
		}
	),
);

### Allow the timer and its watcher to run until they are done.

Reflex::Object->run_all();
pass("run_all() returned");

exit;
