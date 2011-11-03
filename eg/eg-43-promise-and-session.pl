#!/usr/bin/env perl
# vim: ts=2 sw=2 noexpandtab

# This is pretty close to the final syntax.
# TODO - Provide a way to next() on multiple objects at once.
# TODO - Clean out all previous promise-like examples.

use warnings;
use strict;

use lib qw(../lib);

use Reflex::Interval;
use ExampleHelpers qw(eg_say);

my $t = Reflex::Interval->new(
	interval => 1,
	auto_repeat => 1,
);

{
	use POE::Session;  # For KERNEL.

	POE::Session->create(
		inline_states => {
			_start => sub { $_[KERNEL]->delay(tick => 0.5) },
			tick   => sub {
				eg_say("POE::Session ticked...");
				$_[KERNEL]->delay(tick => 0.5);
			},
		},
	);
}

while (my $event = $t->next()) {
	eg_say("next() returned an event (", $event->_name(), ")");
}

__END__

% perl eg-43-promise-and-session.pl
2011-11-02 23:00:04 - POE::Session ticked...
2011-11-02 23:00:05 - next() returned an event (tick)
2011-11-02 23:00:05 - POE::Session ticked...
2011-11-02 23:00:05 - POE::Session ticked...
2011-11-02 23:00:06 - next() returned an event (tick)
2011-11-02 23:00:06 - POE::Session ticked...
2011-11-02 23:00:06 - POE::Session ticked...
2011-11-02 23:00:07 - next() returned an event (tick)
2011-11-02 23:00:07 - POE::Session ticked...
2011-11-02 23:00:07 - POE::Session ticked...
2011-11-02 23:00:08 - next() returned an event (tick)
2011-11-02 23:00:08 - POE::Session ticked...
2011-11-02 23:00:08 - POE::Session ticked...
^C
