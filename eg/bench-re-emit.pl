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

{
	package Thing;
	use Moose;
	extends 'Reflex::Base';

	sub test {
		my ($self, $event) = @_;

		my $i = 100_000;
		while ($i--) {
			$self->re_emit($event, -name => "re_emitted");
		}
	}

	__PACKAGE__->meta->make_immutable;
}

use Reflex::Event;
my $t = Thing->new();

$t->test( Reflex::Event->new( _name => "generic", _emitters => [ ] ) );
