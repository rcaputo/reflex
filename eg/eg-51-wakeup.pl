#!/usr/bin/env perl

use warnings;
use strict;
use lib qw(./lib ../lib ./eg);

use Reflex::Wakeup;
use ExampleHelpers qw(eg_say);

my @wakeups;
my $ding = 0;

for my $delay (1..5) {
	push @wakeups, Reflex::Wakeup->new(
		when    => time() + $delay,
		on_time => sub {
			eg_say "got wakeup $delay";

			# TODO - Can we eliminate the need for this?
			@wakeups = () if ++$ding >= @wakeups;
		},
	);
}

Reflex->run_all();
exit;
