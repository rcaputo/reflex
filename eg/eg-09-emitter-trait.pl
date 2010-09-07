#!/usr/bin/perl

use warnings;
use strict;
use lib qw(../lib);

# Objects may emit events when their members are changed.

{
	package Counter;
	use Moose;
	extends 'Reflex::Base';
	use Reflex::Interval;
	use Reflex::Trait::EmitsOnChange;
	use Reflex::Trait::Observed;

	emits     count   => ( isa => 'Int', default => 0 );
	observes  ticker  => ( isa => 'Maybe[Reflex::Interval]' );

	sub BUILD {
		my $self = shift;

		$self->ticker(
			Reflex::Interval->new(
				interval    => 0.1,
				auto_repeat => 1,
			)
		);
	}

	sub on_ticker_tick {
		my $self = shift;
		$self->count($self->count() + 1);
	}
}

{
	package Watcher;
	use Moose;
	extends 'Reflex::Base';
	use Reflex::Trait::Observed;

	observes counter => ( isa => 'Counter' );

	sub BUILD {
		my $self = shift;
		$self->counter(Counter->new());
	}

	sub on_counter_count {
		my ($self, $args) = @_;
		warn "Watcher sees counter count: $args->{value}\n";
	}
}

# Main.

my $w = Watcher->new();
Reflex->run_all();
exit;
