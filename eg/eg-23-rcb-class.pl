#!/usr/bin/env perl

# This example illustrates explicit callbacks via classes, where
# callback events are mapped to class methods by name.  Methods may be
# named after the events they handle, or they may differ.

# Reflex::Callbacks and the Reflex::Callback helper classes will
# abstract callbacks to fulfill a number of goals.  The goals are
# detailed in docs/requirements.otl and summarized in
# eg/eg-20-rcb-callback.pl

use warnings;
use strict;
use lib qw(../lib);

# Create a thing that will invoke callbacks.  This syntax uses
# explicitly specified cb_class() callbacks and a scalar for the
# methods list.  cb_method() would be slightly more efficient in this
# case, but cb_class() also works.
#
# There is no nonambiguous implicit syntax at this time.  Suggestions
# for one are welcome.

{
	package ScalarHandlerClass;
	use Moose;

	use ExampleHelpers qw(eg_say);
	use Reflex::Callbacks qw(cb_class);
	use ThingWithCallbacks;

	has callback_thing => ( is => 'rw', isa => 'ThingWithCallbacks' );

	sub BUILD {
		my $self = shift;

		$self->callback_thing(
			ThingWithCallbacks->new(
				cb_class(__PACKAGE__, "on_event"),
			)
		);
	}

	sub on_event {
		my ($self, $arg) = @_;
		eg_say("$self - scalar class handled event");
	}

	sub run_thing {
		my $self = shift;
		$self->callback_thing()->run();
	}
}

my $sho = ScalarHandlerClass->new();
$sho->run_thing();

# In this case, a class handles a list of callbacks.  Each callback
# method is named after the event it handles.
#
# There is no nonambiguous implicit syntax for this either, but
# suggestions are welcome.

{
	package ArrayHandlerClass;
	use Moose;

	use ExampleHelpers qw(eg_say);
	use Reflex::Callbacks qw(cb_class);
	use ThingWithCallbacks;

	has callback_thing => ( is => 'rw', isa => 'ThingWithCallbacks' );

	sub BUILD {
		my $self = shift;

		$self->callback_thing(
			ThingWithCallbacks->new(
				cb_class(__PACKAGE__, ["on_event"]),
			)
		);
	}

	sub on_event {
		my ($self, $arg) = @_;
		eg_say("$self - array class handled event");
	}

	sub run_thing {
		my $self = shift;
		$self->callback_thing()->run();
	}
}

my $aho = ArrayHandlerClass->new();
$aho->run_thing();

# In this case, a class handles a hash of callbacks.  Hash keys are
# event names, and the values are the corresponding handler method
# names.  The hash gives classes flexibility in the methods they use.
#
# There is no nonambiguous implicit syntax for this either, but
# suggestions are welcome.

{
	package HashHandlerClass;
	use Moose;

	use ExampleHelpers qw(eg_say);
	use Reflex::Callbacks qw(cb_class);
	use ThingWithCallbacks;

	has callback_thing => ( is => 'rw', isa => 'ThingWithCallbacks' );

	sub BUILD {
		my $self = shift;

		$self->callback_thing(
			ThingWithCallbacks->new(
				cb_class(__PACKAGE__, { on_event => "handle_event" }),
			)
		);
	}

	sub handle_event {
		my ($self, $arg) = @_;
		eg_say("$self - hash class handled event");
	}

	sub run_thing {
		my $self = shift;
		$self->callback_thing()->run();
	}
}

my $hho = HashHandlerClass->new();
$hho->run_thing();
