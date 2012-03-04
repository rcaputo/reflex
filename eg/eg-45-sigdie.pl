#!/usr/bin/perl

# Build a new kind of Interval timer with a POE exception handler
# built into it.  Jams the Reflex role for an interval timer together
# with the role for a signal handler.
#
# The goal is to have a convenient interval timer which can safely
# expose exceptions thrown from its callbacks.  It's based on
# http://blog.afoolishmanifesto.com/archives/1682 and a question from
# fREW Schmidt on irc.perl.org #poe.
#
# Unfortunately lower-level event dispatchers (i.e., POE and the event
# loops it uses) don't know enough about higher-level consumers like
# Reflex to map exceptions back to specific objects.  The
# RobustInterval catches die() globally via $SIG{__DIE__}.  It doesn't
# know which object died, so it reports unhandled exceptions from
# anywhere.
#
# We need to think more carefully about what it means to throw
# exceptions from Reflex event handler callbacks.  What extensible,
# sane things can be done with those exceptions?

{

	package RobustInterval;

	use Moose;
	extends 'Reflex::Base';
	use Reflex::Callbacks qw(make_emitter);

	# Incorporate an interval timer.

	has interval    => (isa => 'Num',  is => 'rw');
	has auto_repeat => (isa => 'Bool', is => 'rw', default => 1);
	has auto_start  => (isa => 'Bool', is => 'ro', default => 1);

	with 'Reflex::Role::Interval' => {
		att_auto_repeat => "auto_repeat",
		att_auto_start  => "auto_start",
		att_interval    => "interval",
		cb_tick         => make_emitter(on_tick => "tick"),
		method_repeat   => "repeat_interval",
		method_start    => "start_interval",
		method_stop     => "stop_interval",
	};

	# Incorporate a signal watcher.

	has signal => (is => 'ro', isa => 'Str',  default => 'DIE');
	has active => (is => 'ro', isa => 'Bool', default => 1);

	with 'Reflex::Role::SigCatcher' => {
		att_signal    => 'signal',
		att_active    => 'active',
		cb_signal     => make_emitter(on_die => "die"),
		method_start  => 'start_signal',
		method_stop   => 'stop_signal',
		method_pause  => 'pause_signal',
		method_resume => 'resume_signal',
	};
}

### Main.

use warnings;
use strict;

use Reflex;

sub event {
	print "looped\n";
	die "lol" if rand() < .5;
}

sub stumble {
	my ($self) = @_;

	warn "$self callback died... stumbling on";

	$self->resume_signal();      # Resume watching for signals.
	$self->repeat_interval();    # Continue the timer.
}

my $ct = RobustInterval->new(
	interval    => 1,
	auto_repeat => 1,
	on_tick     => \&event,
	on_die      => \&stumble,
);

Reflex->run_all();
