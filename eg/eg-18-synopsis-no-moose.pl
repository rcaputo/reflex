#!/usr/bin/env perl
# vim: ts=2 sw=2 noexpandtab

# Use Reflex without Moose.  For people who don't like Moose.

use warnings;
use strict;
use lib qw(../lib);

{
	package App;
	use Reflex::Base;
	use Reflex::Interval;
	use Reflex::Callbacks qw(cb_role);
	use base qw(Reflex::Base);

	sub BUILD {
		my $self = shift;

		$self->{ticker} = Reflex::Interval->new(
			interval    => 1,
			auto_repeat => 1,
		);

		$self->watch($self->{ticker}, cb_role($self, "ticker"));
	}

	sub on_ticker_tick {
		print "tick at ", scalar(localtime), "...\n";
	}
}

exit App->new()->run_all();
