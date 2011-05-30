#!/usr/bin/env perl
# vim: ts=2 sw=2 expandtab

use warnings;
use strict;
use lib qw(../lib);

use Test::More tests => 5;

# Exercise the new "setup" option for emitters and watchers.

{
	package Counter;
	use Moose;
	extends 'Reflex::Base';
	use Reflex::Interval;
	use Reflex::Trait::EmitsOnChange;
	use Reflex::Trait::Watched;

	emits count => (
		isa     => 'Int',
		default => 0,
	);

	watches ticker => (
		isa   => 'Reflex::Interval',
		setup => sub {
			Reflex::Interval->new( interval => 0.1, auto_repeat => 1 )
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
	extends 'Reflex::Base';
	use Reflex::Trait::Watched;

	use Test::More;

	watches counter => (
		isa   => 'Counter|Undef',
		setup => sub { Counter->new() },
	);

	sub on_counter_count {
		my ($self, $args) = @_;
		pass("Watcher sees counter count: $args->{value}/5");

		$self->counter(undef) if $args->{value} >= 5;
	}
}

# Main.

my $w = Watcher->new();
Reflex->run_all();
exit;
