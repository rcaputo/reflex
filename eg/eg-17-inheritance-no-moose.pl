#!/usr/bin/env perl

# Inherit Reflex without Moose.  For people who don't like Moose.

use warnings;
use strict;
use lib qw(../lib);

{
	package App;
	use Reflex::Timer;
	use base qw(Reflex::Timer);

	sub on_timer_tick {
		print "tick at ", scalar(localtime), "...\n";
	}
}

exit App->new(interval => 1, auto_repeat => 1)->run_all();
