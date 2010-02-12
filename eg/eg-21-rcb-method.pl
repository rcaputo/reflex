#!/usr/bin/env perl

# This example illustrates implicit and explicit callbacks via object
# methods.  A ThingWithCallbacks will call methods on objects defined
# in this file.

# Reflex::Callbacks and the Reflex::Callback helper classes will
# abstract callbacks to fulfill a number of goals.  The goals are
# detailed in docs/requirements.otl and summarized in
# eg/eg-20-rcb-callback.pl

use warnings;
use strict;
use lib qw(../lib);

# Create a thing that will invoke callbacks.  This syntax uses
# explicitly specified cb_method() callbacks.  There is no
# nonambiguous implicit syntax at this time.  Suggestions are welcome.

{
	package Object;
	use Moose;

	use ExampleHelpers qw(eg_say);
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
		eg_say("object handled event");
	}

	sub run_thing {
		my $self = shift;
		$self->callback_thing()->run();
	}
}

my $o = Object->new();
$o->run_thing();

__END__

# cb_coderef() reduces context sensitivity at the expense of
# verbosity.

my $thing_two = ThingWithCallbacks->new(
	on_event => cb_coderef(sub { eg_say("explicit callback invoked") }),
);

$thing_two->run();

# cb_coderef is prototyped so it can replace "sub".

my $thing_three = ThingWithCallbacks->new(
	on_event => cb_coderef { eg_say("explicit callback (no sub) invoked") },
);

$thing_three->run();

exit;

__END__

#!/usr/bin/env perl

# As promised in eg-01-discrete-observer.pl, it's time to make the
# syntax nicer and formal.
#
# Most syntaxes have two or three forms.  The first is a simplified,
# context-sensitive form for people who like concise and cryptic.  The
# second is a slightly more verbose, explicit form for people who
# prefer clarity.

use warnings;
use strict;
use lib qw(../lib);

use ExampleHelpers qw(eg_say eg_object);

# TODO - Some kind of :all or :default tag?
use Reflex::Callbacks qw(
	cb_class cb_coderef cb_method cb_object cb_promise cb_role
);

# Objects need to be stored somewhere, but we don't really care about
# them.  Push them onto a list, and forget about them.

my @things;

####################
# Coderef callbacks.
#
# The most flexible callbacks are simply coderefs.  They are clear,
# concise, and allow develpers to emulate continuation-passing style
# by abusing closures.
#
# Coderef callbacks are less suitable for object-oriented programs.
# Using closures, developers can certainly thunk from coderefs to
# objects, but this puts a repetitive burden on developers.  See
# method callbacks below for a more convenient way.

# The simplified contextual style is a plain coderef.

push @things, ThingWithCallbacks->new(
	on_tick => sub { eg_say("simple coderef callback") },
);

# The explicit style uses cb_coderef() to identify the callback type.
# Cb stands for Callback.

push @things, ThingWithCallbacks->new(
	on_tick => cb_coderef( sub { eg_say("explicit coderef callback") } ),
);

# Here is a second variant of cb_coderef() using the (&) prototype to
# eliminate some punctuation and the "sub" keyword.

push @things, ThingWithCallbacks->new(
	on_tick => cb_coderef { eg_say("prototyped coderef callback") },
);

##########################
# Object method callbacks.
#
# Invoking methods as callbacks is another popular choice.  This is
# often more convenient in object-oriented situations.  Methods may be
# invoked on objects or classes.  The syntax is the same in Perl, so
# there's no difference in Reflex.

# The simplified contextual style uses an arrayref, containing the
# object and method name.  While it's a pair of values, we can't use a
# hashref without invalidating the object by stringification.

my $eg_object_1 = eg_object("simplified single event callback object");
push @things, ThingWithCallbacks->new(
	on_tick => [ $eg_object_1, "handler_method" ],
);

# The explicit style uses cb_method() to identify the callback type.

my $eg_object_2 = eg_object("explicit single event callback object");
push @things, ThingWithCallbacks->new(
	on_tick => cb_method( $eg_object_1, "handler_method" ),
);

#############################
# Multiple callbacks at once.
#
# The rest of the variants deal with assigning multiple callbacks to
# a single object.  The above forms will work well, but they involve
# repetition that can feel tedious when a lot of events are handled.
#
# Consider the following example:
#
# my $bot = Reflex::IrcBot->new();
# my $protocol = Reflex::Poco::IRC->new(
#   on_irc_001    => [ $bot, "handle_irc_connected" ],
#   on_irc_public => [ $bot, "handle_irc_public"    ],
#   on_irc_msg    => [ $bot, "handle_irc_private"   ],
#   on_irc_notice => [ $bot, "handle_irc_notice"    ],
#   # ... and a dozen other interesting IRC events ...
# );
#
# The simplified syntax extends the simplified object syntx.  The
# scalar "method_name" is replaced by a list of method names or a map
# of event names to method names.
#
# An arrayref is used when the handler methods and event names are
# identical.
#
# This group of syntaxes specify multiple event names in their
# callback definitions.  They are all lumped under the "callbacks"
# parameter.

my $eg_object_3 = eg_object("simplified multiple method callbacks");
push @things, ThingWithCallbacks->new(
	callbacks => [ $eg_object_3, [qw( event_a event_b event_c )] ],
);

# A hashref is used to map event names to method names.

my $eg_object_4 = eg_object("simplified multiple mapped methods");
push @things, ThingWithCallbacks->new(
	callbacks => [
		$eg_object_3, {
			event_a => "handler_method_a",
			event_b => "handler_method_b",
			event_c => "handler_method_c",
		},
	],
);

# Multiple method callbacks may also be defined with explicit
# syntaxes.

my $eg_object_5 = eg_object("explicit multiple method callbacks");
push @things, ThingWithCallbacks->new(
	callbacks => cb_object(
		$eg_object_5,
		[qw( event_a event_b event_c)]
	),
);

my $eg_object_6 = eg_object("explicit multiple mapped methods");
push @things, ThingWithCallbacks->new(
	callbacks => cb_object(
		$eg_object_6, {
			event_a => "handler_method_a",
			event_b => "handler_method_b",
			event_c => "handler_method_c",
		},
	),
);

#########################
# Class method callbacks.
#
# Class methods may be called using the same syntaxes as object
# method.  As of this writing, the mechanisms for invokving class
# methods are identical in Perl to those of invoking object methods.
# An cb_class() utility function is provided for forward
# compatibility.  If the mechanisms were to diverge in a future
# version of Perl, cb_class() would updated to accommodate the
# change.

# Examples aren't shown since they would look nearly identical to
# previous ones.

#######################
# Role based callbacks.
#
# Role-based callbacks map an object's responses to its destination's
# methods using a simple algorithm.  Method names consist of a prefix
# ("handle"), the sub-object's role (perhaps "dns"), and the
# sub-object's event name ("answer") joined by underscores to become:
# handle_dns_answer().
#
# In theory, each object performs a task or role that contributes to
# the program as a whole.  Larger, more complex objects are built by
# gluing together smaller objects that perform simpler roles.  For
# example, a simple HTTP client might glue together some generic
# objects like so:
#
# HTTP client
#   Keep-alive connection manager ("keepalive" object)
#     Asynchronous DNS resolver ("resolver" object)
#     Asynchronous TCP connector ("connector" object)
#   HTTP stream ("httpstream" object)
#     Asynchronous stream ("stream" object)
#     HTTP protocol ("http" object)
#
# At each level, the container object knows the interfaces for the
# smaller objects within it.  It can therefore assign the smaller
# objects roles and implicitly handle their events by defining methods
# with predictable names.

# Currently there is only the explicit cb_role() function to define
# roles.  Implicit syntax is left for a future release.
#
# $eg_object_7->handle_ticker_tick() is called in response to the
# following Reflex::Timer's "tick" event.

my $eg_object_7 = eg_object("explicit role, explicit prefix");
push @things, ThingWithCallbacks->new(
	callbacks => cb_role($eg_object_7, "ticker", "handle"),
);

# The third parameter to cb_role() is the method prefix, which
# defaults to "handle" if omitted.  $eg_object_8's method
# handle_ticker_tick() is called below.  The "handle" is implied by
# default.

my $eg_object_8 = eg_object("explicit role, implicit prefix");
push @things, ThingWithCallbacks->new(
	callbacks => cb_role($eg_object_8, "ticker"),
);

######################
# Promises or futures.
#
# Promises are the final callback mechanism Reflex supports.  They are
# defined by either not defining callbacks at all, or by defining
# cb_promise() as the callbacks mechanism.
#
# Note however that this code will block.  Nothing beyond it runs
# until the while() loop finishes.  Which may be "never".  Other
# caveats may apply.

my $implicit_promisory_timer = ThingWithCallbacks->new();

while (my $next_event = $implicit_promisory_timer->next_event()) {
	eg_tell("implicit promisory timer generated event $next_event");
}

# People who dislike invisible logic might prefer cb_promise().
#
my $explicit_promisory_timer = ThingWithCallbacks->new(
	callbacks => cb_promise(),
);

while (my $next_event = $explicit_promisory_timer->next_event()) {
	eg_tell("explicit promisory timer generated event $next_event");
}

###############
# Run the demo.

Reflex::Object->run_all();
exit;
