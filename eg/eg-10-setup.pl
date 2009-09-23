#!/usr/bin/env perl

use warnings;
use strict;
use lib qw(../lib);

# Exercise the new "setup" option for Emitter and Observer traits.

{
	package Counter;
	use Moose;
	extends 'Reflex::Object';
	use Reflex::Timer;
	use Reflex::Trait::Observer;
	use Reflex::Trait::Emitter;

	has count   => (
		traits    => ['Reflex::Trait::Emitter'],
		isa       => 'Int',
		is        => 'rw',
		default   => 0,
	);

	has ticker  => (
		traits    => ['Reflex::Trait::Observer'],
		isa       => 'Reflex::Timer',
		is        => 'rw',
		setup     => sub {
			Reflex::Timer->new( interval => 1, auto_repeat => 1 )
		},
	);

	sub on_ticker_tick {
		my $self = shift;
		$self->count($self->count() + 1);
	}
}

{
	package Watcher;
	use Moose;
	extends 'Reflex::Object';

	has counter => (
		traits  => ['Reflex::Trait::Observer'],
		isa     => 'Counter|Undef',
		is      => 'rw',
		setup   => sub { Counter->new() },
	);

	sub on_counter_count {
		my ($self, $args) = @_;
		warn "Watcher sees counter count: $args->{value}\n";

		$self->counter(undef) if $args->{value} >= 5;
	}
}

# Main.

my $w = Watcher->new();
Reflex::Object->run_all();
exit;
