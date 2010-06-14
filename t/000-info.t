#!/usr/bin/env perl

package Satisfy::Moose;

use warnings;
use strict;

use Test::More tests => 3;

use_ok("Moose");
use_ok("POE");
use_ok("Reflex");

diag(
	"Testing Reflex $Reflex::VERSION, ",
	"POE $POE::VERSION, ",
	"Moose $Moose::VERSION, ",
	"Perl $], ",
	"$^X on $^O"
);
