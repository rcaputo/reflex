#!/usr/bin/env perl

# This is pretty close to the final syntax.
# TODO - Coerce a plain coderef without the use of cb_coderef.

use warnings;
use strict;

use lib qw(../lib);

use Reflex::Timer;
use ExampleHelpers qw(eg_say);
use Reflex::Callbacks qw(cb_coderef);

my $t = Reflex::Timer->new(
	interval    => 1,
	auto_repeat => 1,
	on_tick     => cb_coderef { eg_say("timer ticked") },
);

$t->run_all();
