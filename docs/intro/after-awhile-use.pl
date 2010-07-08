#!/usr/bin/env perl

use warnings;
use strict;
use AfterAwhileClass;

my $aa;
$aa = AfterAwhileClass->new(
	awhile  => 1,
	on_done => sub {
		print "AfterAwhileClass done!\n";
		$aa = undef;
	},
);

$aa->run_all();
