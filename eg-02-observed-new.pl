#!/usr/bin/env perl

# An object's observers are registered during construction.
#
# By registering observers during an object's construction, there is
# no time between construction and observation where events may be
# lost.  This is equivalent to eg-01-discrete-observer.pl but without
# the potential for races.

use warnings;
use strict;

use Stage;
use Delay;
use ExampleHelpers qw(tell);

tell("starting watcher object");
my $watcher = Stage->new( );

tell("starting delay object with integrated observation");
my $delay = Delay->new(
	interval    => 1,
	auto_repeat => 1,
	observers   => [
		{
			observer  => $watcher,
			event     => "tick",
			callback  => sub {
				tell("watcher sees 'tick' event");
			},
		},
	],
);

# Run the underlying event loop.
POE::Kernel->run();
exit;
