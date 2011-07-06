#!/usr/bin/env perl

use BaseClass;
use EventySubSystem;

my $object = BaseClass->new();
$object->post(1, 2, 3);
