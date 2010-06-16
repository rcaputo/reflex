#!/usr/bin/env perl

# This example illustrates explicit callbacks via objects, where
# callback events are mapped to handlers by name.  Methods may be
# named after the events they handle, or they may differ.

# Reflex::Callbacks and the Reflex::Callback helper classes will
# abstract callbacks to fulfill a number of goals.  The goals are
# detailed in docs/requirements.otl and summarized in
# eg/eg-20-rcb-callback.pl

use warnings;
use strict;
use lib qw(t/lib);

use Test::More tests => 6;

# Create a thing that will invoke callbacks.  This syntax uses
# explicitly specified cb_object() callbacks and a scalar for the
# methods list.  cb_method() would be slightly more efficient in this
# case, but cb_object() also works.
#
# There is no nonambiguous implicit syntax at this time.  Suggestions
# for one are welcome.

{
	package ScalarHandlerObject;
	use Moose;

	use Reflex::Callbacks qw(cb_object);
	use ThingWithCallbacks;

	has callback_thing => ( is => 'rw', isa => 'ThingWithCallbacks' );

	sub BUILD {
		my $self = shift;

		$self->callback_thing(
			ThingWithCallbacks->new(
				cb_object($self, "event"),
			)
		);
	}

	sub event {
		my ($self, $arg) = @_;
		Test::More::pass("$self - scalar object handled event");
	}

	sub run_thing {
		my $self = shift;
		$self->callback_thing()->run();
	}
}

my $sho = ScalarHandlerObject->new();
$sho->run_thing();

pass("$sho - scalar handler object ran to completion");

# In this case, an object handles a list of callbacks.  Each callback
# method is named after the event it handles.
#
# There is no nonambiguous implicit syntax for this either, but
# suggestions are welcome.

{
	package ArrayHandlerObject;
	use Moose;

	use Reflex::Callbacks qw(cb_object);
	use ThingWithCallbacks;

	has callback_thing => ( is => 'rw', isa => 'ThingWithCallbacks' );

	sub BUILD {
		my $self = shift;

		$self->callback_thing(
			ThingWithCallbacks->new(
				cb_object($self, ["event"]),
			)
		);
	}

	sub event {
		my ($self, $arg) = @_;
		Test::More::pass("$self - array object handled event");
	}

	sub run_thing {
		my $self = shift;
		$self->callback_thing()->run();
	}
}

my $aho = ArrayHandlerObject->new();
$aho->run_thing();

pass("$aho - array handler object ran to completion");

# In this case, an object handles a hash of callbacks.  Hash keys are
# event names, and the values are the corresponding handler method
# names.  The hash gives classes flexibility in the methods they use.
#
# There is no nonambiguous implicit syntax for this either, but
# suggestions are welcome.

{
	package HashHandlerObject;
	use Moose;

	use Reflex::Callbacks qw(cb_object);
	use ThingWithCallbacks;

	has callback_thing => ( is => 'rw', isa => 'ThingWithCallbacks' );

	sub BUILD {
		my $self = shift;

		$self->callback_thing(
			ThingWithCallbacks->new(
				cb_object($self, { event => "handle_event" }),
			)
		);
	}

	sub handle_event {
		my ($self, $arg) = @_;
		Test::More::pass("$self - hash object handled event");
	}

	sub run_thing {
		my $self = shift;
		$self->callback_thing()->run();
	}
}

my $hho = HashHandlerObject->new();
$hho->run_thing();

pass("$hho - hash handler object ran to completion");

exit;
