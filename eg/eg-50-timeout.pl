#!/usr/bin/env perl
# vim: ts=2 sw=2 noexpandtab

use warnings;
use strict;
use lib qw(./lib ../lib ./eg);

use Reflex::Timeout;
use ExampleHelpers qw(eg_say);

my $to = Reflex::Timeout->new(
	delay   => 1,
	on_done => \&handle_timeout,
);

Reflex->run_all();
exit;

sub handle_timeout {
	eg_say "got timeout";
	$to->reset();
}
