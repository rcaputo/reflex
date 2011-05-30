#!/usr/bin/env perl
# vim: ts=2 sw=2 noexpandtab

# Inherit Reflex without Moose.  For people who don't like Moose.

use warnings;
use strict;
use lib qw(../lib);

{
	package App;
	use Reflex::Interval;
	use base qw(Reflex::Interval);

	sub on_tick {
		print "tick at ", scalar(localtime), "...\n";

		# Auto-repeat is defined in the callback.
		# It doesn't work when we override the callback entirely.
		# TODO - How can this be mitigated?  after() in the role?
		shift()->repeat();
	}
}

exit App->new(interval => 1, auto_repeat => 1)->run_all();
