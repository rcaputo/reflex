#!/usr/bin/env perl

# Use Reflex without Moose.  For people who don't like Moose.

use warnings;
use strict;
use lib qw(../lib);

{
	package App;
	use Reflex::Object;
	use Reflex::Timer;
	use Reflex::Callbacks qw(cb_role);
	use base qw(Reflex::Object);

	sub BUILD {
		my $self = shift;

		$self->{ticker} = Reflex::Timer->new(
			interval    => 1,
			auto_repeat => 1,
		);

		$self->observe($self->{ticker}, cb_role($self, "ticker"));
	}

	sub on_ticker_tick {
		print "tick at ", scalar(localtime), "...\n";
	}
}

exit App->new()->run_all();
