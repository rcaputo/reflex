Documenting Reflex syntax evolution.

=head1 Gathering callbacks.

Reflex::Role::Reactive
	Has the cb() member.
	BUILD
		Maps constructor parameters to callbacks.
		Maps callback types to watchers:
			discrete callbacks = discrete watchers
			role callbacks = role watchers
			no callbacks = unwatched (promise?)

=head1 Reflex::Role::Reactive::BUILD calls cb_gather()

emit() syntax is preserved.
1. Role::Reactive handles it normally.
2. Local delivery is through the callback object.

$self->emit( event => \%args );

=head1 Callback constructor parameter.

=cut

my $timer = Reflex::Interval->new(
	interval => 5,
	auto_repeat => 1,
	on_tick => cb_coderef(\&subroutine),
);

my $timer = Reflex::Interval->new(
	interval => 5,
	auto_repeat => 1,
	on_tick => cb_method($self, "method"),
);

my $timer = Reflex::Interval->new(
	interval => 5,
	auto_repeat => 1,
	on_tick => cb_method("class", "method"),
);

=head1 Role constructor parameter.

=cut

my $timer = Reflex::Interval->new(
	interval => 5,
	auto_repeat => 1,
	cb_role($self, "rolename"),
);

=head1 Promise.

=cut

my $timer = Reflex::Interval->new(
	interval => 5,
	auto_repeat => 1,
	# cb_promise
);

while (my $event = $timer->next()) {
	...;
}

=head1 Watcher.

=cut

my $timer = Reflex::Interval->new(
	interval => 5,
	auto_repeat => 1,
	promise => 1,
);

$self->watch(
	watcher   => $timer,
	event     => "tick",
	callback  => ANY_RCB_EXCEPT_PROMISE,
);

=head1 Promise Again

The current syntax is too verbose.

$watcher has no purpose except to call watch().

Perhaps $watcher could be replaced by a Promise class that watches
and then returns events?  Similar to PromiseThing in
eg-25-rcb-promise.pl?

=cut

#!/usr/bin/env perl

use warnings;
use strict;

use lib qw(../lib);

use Reflex::Interval;
use Reflex::Callbacks qw(cb_promise);
use ExampleHelpers qw(eg_say);

my $watcher = Reflex::Base->new();

my $promise;
my $timer = Reflex::Interval->new(
	interval    => 1,
	auto_repeat => 1,
);

$watcher->watch($timer, cb_promise(\$promise));

while (my $event = $promise->next()) {
	eg_say("next() returned an event (@$event)");
}
