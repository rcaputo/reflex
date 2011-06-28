package Reflex::Interval;
# vim: ts=2 sw=2 noexpandtab

use Moose;
extends 'Reflex::Base';
use Reflex::Callbacks qw(make_emitter);

has interval    => ( isa => 'Num', is  => 'rw' );
has auto_repeat => ( isa => 'Bool', is => 'rw', default => 1 );
has auto_start  => ( isa => 'Bool', is => 'ro', default => 1 );

with 'Reflex::Role::Interval' => {
	att_auto_repeat => "auto_repeat",
	att_auto_start  => "auto_start",
	att_interval    => "interval",
	cb_tick         => make_emitter(on_tick => "tick"),
	method_repeat   => "repeat",
	method_start    => "start",
	method_stop     => "stop",
};

1;

__END__

=head1 NAME

Reflex::Interval - A stand-alone multi-shot periodic callback

=head1 SYNOPSIS

As with all Reflex objects, Reflex::Interval may be used in many
different ways.

Inherit it and override its on_tick() callback, with or without using
Moose.

	package App;
	use Reflex::Interval;
	use base qw(Reflex::Interval);

	sub on_tick {
		print "tick at ", scalar(localtime), "...\n";
		shift()->repeat();
	}

Run it as a promise that generates periodic events.  All other Reflex
objects will also be running while C<<$pt->next()>> is blocked.

	my $pt = Reflex::Interval->new(
		interval    => 1 + rand(),
		auto_repeat => 1,
	);

	while (my $event = $pt->next()) {
		eg_say("promise timer returned an event ($event->{name})");
	}

Plain old callbacks:

	my $ct = Reflex::Interval->new(
		interval    => 1,
		auto_repeat => 1,
		on_tick     => sub { print "coderef callback triggered\n" },
	);
	Reflex->run_all();

And so on.  See Reflex, Reflex::Base and Reflex::Role::Reactive for
details.

=head1 DESCRIPTION

Reflex::Interval invokes a callback after a specified interval of time
has passed, and then after every subsequent interval of time.
Interval timers may be stopped and started.  Their timers may be
automatically or manually repeated.

=head2 Public Attributes

=head3 interval

Implemented and documented by L<Reflex::Role::Interval/interval>.

=head3 auto_repeat

Implemented and documented by L<Reflex::Role::Interval/auto_repeat>.

=head3 auto_start

Implemented and documented by L<Reflex::Role::Interval/auto_start>.

=head2 Public Callbacks

=head3 on_tick

Implemented and documented by L<Reflex::Role::Interval/cb_tick>.

=head2 Public Methods

=head3 repeat

Implemented and documented by L<Reflex::Role::Interval/method_repeat>.

=head3 start

Implemented and documented by L<Reflex::Role::Interval/method_start>.

=head3 stop

Implemented and documented by L<Reflex::Role::Interval/method_stop>.

=head1 EXAMPLES

TODO - Many.  Link to them.

=head1 SEE ALSO

L<Reflex>
L<Reflex::Role>
L<Reflex::Role::Interval>
L<Reflex::Role::Timeout>
L<Reflex::Role::Wakeup>
L<Reflex::Timeout>
L<Reflex::Wakeup>

L<Reflex/ACKNOWLEDGEMENTS>
L<Reflex/ASSISTANCE>
L<Reflex/AUTHORS>
L<Reflex/BUGS>
L<Reflex/BUGS>
L<Reflex/CONTRIBUTORS>
L<Reflex/COPYRIGHT>
L<Reflex/LICENSE>
L<Reflex/TODO>

=cut
