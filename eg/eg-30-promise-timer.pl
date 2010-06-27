#!/usr/bin/env perl

use warnings;
use strict;

use lib qw(../lib);

use Reflex::Timer;
use Reflex::Callbacks qw(cb_promise);
use ExampleHelpers qw(eg_say);

my $timer = Reflex::Timer->new(
	interval    => 1,
	auto_repeat => 1,
);

my $promise;
my $watcher = Reflex::Base->new();
$watcher->watch($timer, cb_promise(\$promise));

while (my $event = $promise->next()) {
	eg_say("next() returned an event ($event->{name})");
}
