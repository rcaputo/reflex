#!/usr/bin/env perl

use warnings;
use strict;

use lib qw(../lib);

use Reflex::Timer;
use Reflex::Callbacks qw(cb_promise);
use ExampleHelpers qw(eg_say);

# Most verbose syntax.
# TODO - The $watcher is useless.  How can it be eliminated?

{
	my $timer = Reflex::Timer->new(
		interval    => 1,
		auto_repeat => 1,
	);

	my $promise;
	my $watcher = Reflex::Object->new();
	$watcher->observe($timer, cb_promise(\$promise));

	while (my $event = $promise->wait()) {
		eg_say("wait() returned an event (@$event)");
	}
}

# Wrap some of the syntax into a Reflex::Promise object.
# TODO - Still has a $watcher, but it's hidden in a Reflex::Promise.

{
	use ReflexPromise;

	my $p = ReflexPromise->new(
		object => Reflex::Timer->new(
			interval    => 1,
			auto_repeat => 1,
		)
	);

	while (my $event = $p->wait()) {
		eg_say("wait() returned an event (@$event)");
	}
}
