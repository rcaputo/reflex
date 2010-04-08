Documenting Reflex syntax evolution.

=head1 Gathering callbacks.

Reflex::Role::Object
	Has the cb() member.
	BUILD
		Maps constructor parameters to callbacks.
		Maps callback types to observers:
			discrete callbacks = discrete observers
			role callbacks = role observers
			no callbacks = unobserved (promise?)

=head1 Reflex::Role::Object::BUILD calls cb_gather()

emit() syntax is preserved.
1. Role::Object handles it normally.
2. Local delivery is through the callback object.

$self->emit( event => \%args );

=head1 Callback constructor parameter.

=cut

my $timer = Reflex::Timer->new(
	interval => 5,
	auto_repeat => 1,
	on_tick => cb_coderef(\&subroutine),
);

my $timer = Reflex::Timer->new(
	interval => 5,
	auto_repeat => 1,
	on_tick => cb_method($self, "method"),
);

my $timer = Reflex::Timer->new(
	interval => 5,
	auto_repeat => 1,
	on_tick => cb_method("class", "method"),
);

=head1 Role constructor parameter.

=cut

my $timer = Reflex::Timer->new(
	interval => 5,
	auto_repeat => 1,
	cb_role($self, "rolename"),
);

=head1 Promise.

=cut

my $timer = Reflex::Timer->new(
	interval => 5,
	auto_repeat => 1,
	# cb_promise
);

while (my $event = $timer->wait()) {
	...;
}

=head1 Observer.

=cut

my $timer = Reflex::Timer->new(
	interval => 5,
	auto_repeat => 1,
	promise => 1,
);

$self->observe(
	observed => $timer,
	event     => "tick",
	callback  => ANY_RCB_EXCEPT_PROMISE,
);

=head1 Promise Again

The current syntax is too verbose.

$watcher has no purpose except to call observe().

Perhaps $watcher could be replaced by a Promise class that observes
and then returns events?  Similar to PromiseThing in
eg-25-rcb-promise.pl?

=cut

#!/usr/bin/env perl

use warnings;
use strict;

use lib qw(../lib);

use Reflex::Timer;
use Reflex::Callbacks qw(cb_promise);
use ExampleHelpers qw(eg_say);

my $watcher = Reflex::Object->new();

my $promise;
my $timer = Reflex::Timer->new(
	interval    => 1,
	auto_repeat => 1,
);

$watcher->observe($timer, cb_promise(\$promise));

while (my $event = $promise->wait()) {
	eg_say("wait() returned an event (@$event)");
}
