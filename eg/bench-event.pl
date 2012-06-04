#!/usr/bin/env perl

# A program to benchmark and/or profile event creation and
# destruction.
#
# Sample usage:
#
#   perl -d:NYTProf bench-event.pl
#   nytprofhtml
#   open nytprof/index.html

use warnings;
use strict;

use Reflex::Event;

my $i = 100_000;
while ($i--) {
	my $e = Reflex::Event->new( _name => 'anything', _emitters => [ ] );
}
