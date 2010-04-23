#!/usr/bin/env perl

# This example illustrates explicit a promise-like form of callback.
# The promise acts as an event pipeline.  Events emitted from the
# object are available one at a time from a promise method.
#
# Promises require some form of asynchrony.  This example is larger
# than the others because it includes some custom mock-up code to
# stand in for the rest of Reflex.

# Reflex::Callbacks and the Reflex::Callback helper classes will
# abstract callbacks to fulfill a number of goals.  The goals are
# detailed in docs/requirements.otl and summarized in
# eg/eg-20-rcb-callback.pl

use warnings;
use strict;
use lib qw(../lib);

# Create a thing that will invoke callbacks.

{
	package PromiseThing;
	use Moose;
	extends 'Reflex::Object';
	use Reflex::Timer;
	use Reflex::Callbacks qw(gather_cb);

	has ticker => (
		isa     => 'Reflex::Timer',
		is      => 'rw',
		setup   => { interval => 1, auto_repeat => 1 },
		traits  => [ 'Reflex::Trait::Observer' ],
	);

	has cb => ( is => 'rw', isa => 'Reflex::Callbacks' );

	sub BUILD {
		my ($self, $arg) = @_;
		$self->cb(gather_cb($arg));
	}

	sub on_ticker_tick {
		my $self = shift;
		$self->cb()->deliver( event => {} );
	}
}

use Reflex::Callbacks qw(cb_promise);
use ExampleHelpers qw(eg_say);

my $promise;
my $pt = PromiseThing->new( cb_promise(\$promise) );

while (my $event = $promise->wait()) {
	eg_say("wait() returned an event ($event->{name})");
}
