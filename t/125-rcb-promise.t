#!/usr/bin/env perl
# vim: ts=2 sw=2 noexpandtab

# This example illustrates explicit a promise-like form of callback.
# The promise acts as an event pipeline.  Events emitted from the
# object are available one at a time from a promise method.
#
# Promises require some form of asynchrony.  This example is larger
# than the others because it includes some custom mock-up code to
# stand in for the rest of Reflex.

# Reflex::Callbacks and the Reflex::Callback helper classes will
# abstract callbacks to fulfill a number of goals.  The goals are
# detailed in docs/TODO.otl and summarized in eg/eg-20-rcb-callback.pl

use warnings;
use strict;
use lib qw(t/lib);

use Test::More tests => 3;

# Create a thing that will invoke callbacks.

{
	package PromiseThing;
	use Moose;
	extends 'Reflex::Base';
	use Reflex::Interval;
	use Reflex::Callbacks qw(gather_cb);
	use Reflex::Trait::Watched qw(watches);

	watches ticker => (
		isa     => 'Reflex::Interval',
		setup   => { interval => 1, auto_repeat => 1 },
	);

	has cb => ( is => 'rw', isa => 'Reflex::Callbacks' );

	sub BUILD {
		my ($self, $arg) = @_;
		$self->cb(gather_cb($self, $arg));
	}

	sub on_ticker_tick {
		my $self = shift;
		$self->cb()->deliver( event => {} );
	}
}

use Reflex::Callbacks qw(cb_promise);

my $promise;
my $pt = PromiseThing->new( cb_promise(\$promise) );

for (1..3) {
	my $event = $promise->next();
	last unless $event;
	pass("next($_) returned an event ($event->{name})");
}
