#!/usr/bin/env perl
# vim: ts=2 sw=2 noexpandtab

use warnings;
use strict;

use lib qw(../lib);

use Reflex::Interval;
use Reflex::Callbacks qw(cb_promise);
use ExampleHelpers qw(eg_say);

my $timer = Reflex::Interval->new(
	interval    => 1,
	auto_repeat => 1,
);

my $promise;
my $watcher = Reflex::Base->new();
$watcher->watch($timer, cb_promise(\$promise));

while (my $event = $promise->next()) {
	eg_say("next() returned an event (", $event->_name(), ")");
}
