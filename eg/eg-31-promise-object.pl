#!/usr/bin/env perl

use warnings;
use strict;

use lib qw(../lib);

use Reflex::Interval;
use ExampleHelpers qw(eg_say);
use ReflexPromise;

my $p = ReflexPromise->new(
	object => Reflex::Interval->new(
		interval    => 1,
		auto_repeat => 1,
	)
);

while (my $event = $p->next()) {
	eg_say("next() returned an event ($event->{name})");
}
