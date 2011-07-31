#!/usr/bin/env perl
# vim: ts=2 sw=2 noexpandtab

use warnings;
use strict;
use lib qw(./lib ../lib ./eg);

{
	package Foo;
	use Moose;
	extends 'Reflex::Timeout';
	use ExampleHelpers qw(eg_say);

	sub on_done {
		eg_say "custom got timeout";
		$_[0]->reset();
	}
}

my $to = Foo->new(delay => 1);
Reflex->run_all();
exit;
