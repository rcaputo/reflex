#!/usr/bin/env perl
# vim: ts=2 sw=2 noexpandtab

# This is pretty close to the final syntax.
# TODO - Provide a way to next() on multiple objects at once.
# TODO - Clean out all previous promise-like examples.

use warnings;
use strict;

use lib qw(../lib);

use Reflex::Interval;
use ExampleHelpers qw(eg_say);

my $t = Reflex::Interval->new(
	interval => 1,
	auto_repeat => 1,
);

while (my $event = $t->next()) {
	eg_say("next() returned an event ($event->{name})");
}
