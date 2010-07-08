#!/usr/bin/env perl

use warnings;
use strict;

use AsyncAwhileClass;

my $aa = AsyncAwhileClass->new(awhile => 1);

my $response = $aa->next();
print "Response callback: $response->{name}\n";
