#!/usr/bin/env perl
# vim: ts=2 sw=2 noexpandtab

# This is pretty close to the final syntax.
# TODO - Provide a way to next() on multiple objects at once.
# ...... maybe by next() on a collection?
# TODO - Clean out all previous promise-like examples.

use warnings;
use strict;

use lib qw(../lib);

use Reflex::Interval;
use ExampleHelpers qw(eg_say);

### Handle timer ticks with coderefs.

use Reflex::Callbacks qw(cb_coderef);
my $ct = Reflex::Interval->new(
	interval    => 1 + rand(),
	auto_repeat => 1,
	on_tick     => cb_coderef( sub { eg_say("coderef callback triggered") } ),
);

### Handle timer ticks with object methods.  Class methods work, too.

{
	package MethodHandler;
	use Moose;
	extends 'Reflex::Base';
	use Reflex::Callbacks qw(cb_method);
	use ExampleHelpers qw(eg_say);

	has ticker => (
		isa     => 'Maybe[Reflex::Interval]',
		is      => 'rw',
	);

	sub BUILD {
		my $self = shift;
		$self->ticker(
			Reflex::Interval->new(
				interval    => 1 + rand(),
				auto_repeat => 1,
				on_tick     => cb_method($self, "callback"),
			)
		);
	}

	sub callback {
		eg_say("method callback triggered");
	}
}

my $mh = MethodHandler->new();

### Handle timer ticks with objects.
### This is a convenience wrapper for mapping several events to
### methods in one go.

{
	package ObjectHandler;
	use Moose;
	extends 'Reflex::Base';
	use Reflex::Callbacks qw(cb_object);
	use ExampleHelpers qw(eg_say);

	has ticker => (
		isa     => 'Maybe[Reflex::Interval]',
		is      => 'rw',
	);

	sub BUILD {
		my $self = shift;
		$self->ticker(
			Reflex::Interval->new(
				interval    => 1 + rand(),
				auto_repeat => 1,
				cb_object($self, { tick => "callback" }),
			)
		);
	}

	sub callback {
		eg_say("object callback triggered");
	}
}

my $oh = ObjectHandler->new();

### Handle timer ticks with role-based method names.

{
	package RoleHandler;
	use Moose;
	extends 'Reflex::Base';
	use Reflex::Callbacks qw(cb_role);
	use ExampleHelpers qw(eg_say);

	has ticker => (
		isa     => 'Maybe[Reflex::Interval]',
		is      => 'rw',
	);

	sub BUIILD {
		my $self = shift;
		$self->ticker(
			Reflex::Interval->new(
				interval    => 1 + rand(),
				auto_repeat => 1,
				cb_role($self, "timer"),
			)
		);
	}

	sub on_timer_tick {
		eg_say("object callback triggered");
	}
}

my $rh = RoleHandler->new();

### Poll for events with promises.  Goes last because the while() loop
### will "block".  Meanwhile, next() is also allowing the other timers
### to run.

my $pt = Reflex::Interval->new(
	interval    => 1 + rand(),
	auto_repeat => 1,
);

while (my $event = $pt->next()) {
	eg_say("promise timer returned an event ($event->{name})");
}
