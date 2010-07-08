#!/usr/bin/env perl

use warnings;
use strict;
use AfterAwhileSubclass;
use Reflex::Callbacks qw(cb_coderef);

my $aa = AfterAwhileSubclass->new(awhile => 1);

$aa->run_all();
