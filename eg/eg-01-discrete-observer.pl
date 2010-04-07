#!/usr/bin/env perl

# Watch another object, already created.
#
# Create a Reflex::Object that may emit events before it can be
# watched.  Create a watcher after the fact, which then watches the
# Reflex::Timer.
#
# Warning: Events can be missed in a truly concurrent system if there
# is time between the creation of a watched object and registering its
# events' watchers.  See eg-02-watched-new.pl for a safer alternative.
#
# TODO - Another option is to create an object in a stopped state,
# then start it after watchers have been registered.
#
# Note: This is verbose syntax.  More concise, convenient syntax has
# been developed and appears in later examples.

use warnings;
use strict;
use lib qw(../lib);

use Reflex::Object;
use Reflex::Timer;
use ExampleHelpers qw(eg_say);
use Reflex::Callbacks qw(cb_coderef);

eg_say("starting timer object");
my $timer = Reflex::Timer->new( interval => 1, auto_repeat => 1 );

eg_say("starting watcher object");
my $watcher = Reflex::Object->new();

eg_say("watcher watching timer");
$watcher->observe(
	$timer,
	tick => cb_coderef( sub { eg_say("watcher sees 'tick' event") } ),
);

# Run the objects until they are done.
Reflex::Object->run_all();
exit;
