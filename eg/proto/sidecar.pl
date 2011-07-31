#!/usr/bin/env perl
# vim: ts=2 sw=2 noexpandtab

use Moose;
use Sidecar;

{
	package BlockingService;

	use Moose;

	has counter => ( is => 'rw', isa => 'Int', default => 0 );

	sub next {
		my $self = shift;

		return "pid($$) counter = " . $self->counter( $self->counter() + 1 );
	}
}

my $scbs = Sidecar->new(class => 'BlockingService');

