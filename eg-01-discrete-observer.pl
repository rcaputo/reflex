#!/usr/bin/env perl

# Observe another object, already created.
#
# Create a Delay object that may emit events befoe it can be observed.
# Create an observer after the fact, which then observes the Delay.
#
# Warning: Events can be missed in a truly concurrent system if there
# is time between the creation of an observed object and registering
# its events' observers.  See eg-02-observed-new.pl for a safer
# alternative.
#
# TODO - Another option is to create an object in a stopped state,
# then start it after observers have been registered.

use warnings;
use strict;

use Stage;
use Delay;
use ExampleHelpers qw(tell);

tell("starting delay object");
my $delay = Delay->new( interval => 1, auto_repeat => 1 );

tell("starting watcher object");
my $watcher = Stage->new();

tell("watcher watching delay");
$watcher->observe(
	observed  => $delay,
	event     => "tick",
	callback  => sub {
		tell("watcher sees 'tick' event");
	},
);

# Run the underlying event loop.
POE::Kernel->run();
exit;
