#!/usr/bin/env perl

use warnings;
use strict;

my $aa;

{
	package Class;
	use Moose;
	extends 'Reflex::Base';
	sub method {
		print "AfterAwhileClass called a method!\n";
		$aa = undef;
	}
}

use AfterAwhileClass;
use Reflex::Callbacks qw(cb_method);

my $object = Class->new();

$aa = AfterAwhileClass->new(
	awhile  => 1,
	on_done => cb_method($object, "method"),
);

$aa->run_all();
