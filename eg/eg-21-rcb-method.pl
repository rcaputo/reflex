#!/usr/bin/env perl

# This example illustrates explicit callbacks via object methods.  A
# ThingWithCallbacks will call methods on objects defined in this
# file.

# Reflex::Callbacks and the Reflex::Callback helper classes will
# abstract callbacks to fulfill a number of goals.  The goals are
# detailed in docs/requirements.otl and summarized in
# eg/eg-20-rcb-callback.pl

use warnings;
use strict;
use lib qw(../lib);

use Test::More tests => 2;

# Create a thing that will invoke callbacks.  This syntax uses
# explicitly specified cb_method() callbacks.  There is no
# nonambiguous implicit syntax at this time.  Suggestions are welcome.

{
	package Object;
	use Moose;

	use Reflex::Callbacks qw(cb_method);
	use ThingWithCallbacks;

	has callback_thing => ( is => 'rw', isa => 'ThingWithCallbacks' );

	sub BUILD {
		my $self = shift;

		$self->callback_thing(
			ThingWithCallbacks->new(
				on_event => cb_method($self, "handle_event")
			)
		);
	}

	sub handle_event {
		my ($self, $arg) = @_;
		Test::More::pass("object handled event");
	}

	sub run_thing {
		my $self = shift;
		$self->callback_thing()->run();
	}
}

my $o = Object->new();
$o->run_thing();

pass("object ran to completion");
