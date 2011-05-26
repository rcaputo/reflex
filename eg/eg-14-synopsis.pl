#!/usr/bin/env perl

use warnings;
use strict;
use lib qw(../lib);

{
	package App;
	use Moose;
	extends 'Reflex::Base';
	use Reflex::Interval;
	use Reflex::Trait::Watched;

	watches ticker => (
		isa   => 'Reflex::Interval',
		setup => { interval => 1, auto_repeat => 1 },
	);

	sub on_ticker_tick {
		print "tick at ", scalar(localtime), "...\n";
	}
}

exit App->new()->run_all();
