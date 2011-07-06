#!/usr/bin/env perl

use BaseUseWith (with => "EventyRole");

my $object = BaseUseWith->new();
$object->post(1, 2, 3);
