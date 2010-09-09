#!/usr/bin/env perl

# This example illustrates implicit and explicit callbacks via plain
# coderefs.  Coderef callbacks are clear and concise.  They allow
# developers to take advantage of closure tricks, including
# implementing a form of continuation-passing style.
#
# They are less suitable for object-oriented programs.  See most other
# forms of Reflex::Callback for more object oriented callbacks.

# Reflex::Callbacks and the Reflex::Callback helper classes will
# abstract callbacks to fulfill the following goals:
#
# 1. A module's consumer decides how it will be called back.
# 2. Module implementations will use a single interface that
#    represents the abstract notion of callbacks.  Consumers' chosen
#    callback implementations will handle the rest.
# 3. Every known form of callback will be supported, so that module
#    consumers aren't limited to a single, possibly undesirable
#    callback mechanism.
# 4. Common callback mechanisms may be specified by concise,
#    contextual syntax.
# 5. All callback mechanisms may be specified by slightly verbose but
#    unambiguous syntax.

# Ideally all the eg-*-rcb-*.pl examples will use the identical
# ThingWithCallbacks.  That class will have no custom callback logic
# at all.

use warnings;
use strict;
use lib qw(t/lib);

use Test::More tests => 7;

use Reflex::Callbacks qw(cb_coderef);
use ThingWithCallbacks;

# Create a thing that will invoke callbacks.
# This syntax uses contextually specified coderef callbacks.
# Circular reference on $thing_one leaks memory.

my $thing_one;
$thing_one = ThingWithCallbacks->new(
	on_event => sub {
		pass("contextual callback invoked");
		is($_[0], $thing_one, "contextual callback got self");
	},
);

$thing_one->run();

# cb_coderef() reduces context sensitivity at the expense of
# verbosity.
# Circular reference on $thing_two leaks memory.

my $thing_two;
$thing_two = ThingWithCallbacks->new(
	on_event => cb_coderef(
		sub {
			is($_[0], $thing_two, "explicit callback got self");
			pass("explicit callback invoked");
		}
	),
);

$thing_two->run();

# cb_coderef is prototyped so it can replace "sub".
# Circular reference on $thing_three leaks memory.

my $thing_three;
$thing_three = ThingWithCallbacks->new(
	on_event => cb_coderef {
		is($_[0], $thing_three, "explicit callback (no sub) got self");
		pass("explicit callback (no sub) invoked");
	},
);

$thing_three->run();
pass("object ran to completion");

exit;
