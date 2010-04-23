#!/usr/bin/env perl

# This is pretty close to the final syntax.
# TODO - Provide a way to wait() on multiple objects at once.
# TODO - Clean out all previous promise-like examples.

use warnings;
use strict;

use lib qw(../lib);

use Reflex::Timer;
use ExampleHelpers qw(eg_say);

my $t = Reflex::Timer->new(
	interval => 1,
	auto_repeat => 1,
);

while (my $event = $t->wait()) {
	eg_say("wait() returned an event ($event->{name})");
}
