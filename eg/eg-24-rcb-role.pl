#!/usr/bin/env perl

# This example illustrates explicit callbacks via Reflex roles.  An
# object is assigned a role to play in its owner.  Event names are
# mapped to methods by joining a prefix ("on" by default), the role
# name, and the event name.  For example, a DNS resolver might have
# the role "resolver".  The invocant's on_resolver_answer() would be
# called by default to invoke the resolver's "answer" event.

# Reflex::Callbacks and the Reflex::Callback helper classes will
# abstract callbacks to fulfill a number of goals.  The goals are
# detailed in docs/requirements.otl and summarized in
# eg/eg-20-rcb-callback.pl

use warnings;
use strict;
use lib qw(../lib);

# Create a thing that will invoke callbacks.  cb_role() defines the
# thing's role within the RoleHandlerObject.
#
# There is no nonambiguous implicit syntax at this time.  Suggestions
# for one are welcome.

{
	package RoleHandlerObject;
	use Moose;

	use ExampleHelpers qw(eg_say);
	use Reflex::Callbacks qw(cb_role);
	use ThingWithCallbacks;

	has callback_thing => ( is => 'rw', isa => 'ThingWithCallbacks' );

	sub BUILD {
		my $self = shift;

		$self->callback_thing(
			ThingWithCallbacks->new( cb_role($self, "thing") )
		);
	}

	sub on_thing_event {
		my ($self, $arg) = @_;
		eg_say("$self - role object handled event");
	}

	sub run_thing {
		my $self = shift;
		$self->callback_thing()->run();
	}
}

my $sho = RoleHandlerObject->new();
$sho->run_thing();

# This form invokes a class methods.

{
	package RoleHandlerClass;
	use Moose;

	use ExampleHelpers qw(eg_say);
	use Reflex::Callbacks qw(cb_role);
	use ThingWithCallbacks;

	has callback_thing => ( is => 'rw', isa => 'ThingWithCallbacks' );

	sub BUILD {
		my $self = shift;

		$self->callback_thing(
			ThingWithCallbacks->new( cb_role(__PACKAGE__, "thing") )
		);
	}

	sub on_thing_event {
		my ($self, $arg) = @_;
		eg_say("$self - role class handled event");
	}

	sub run_thing {
		my $self = shift;
		$self->callback_thing()->run();
	}
}

my $shc = RoleHandlerClass->new();
$shc->run_thing();
