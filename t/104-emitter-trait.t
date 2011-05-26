#!/usr/bin/perl

use warnings;
use strict;
use lib qw(../lib);

use Test::More tests => 4;

# Objects may emit events when their members are changed.

{
	package Counter;
	use Moose;
	extends 'Reflex::Base';
	use Reflex::Interval;
	use Reflex::Trait::EmitsOnChange;
	use Reflex::Trait::Watched;

	use Test::More;

	emits    count   => ( isa => 'Int', default => 0 );
	watches  ticker  => ( isa => 'Maybe[Reflex::Interval]' );

	sub BUILD {
		my $self = shift;

		$self->ticker(
			Reflex::Interval->new(
				interval    => 0.1,
				auto_repeat => 1,
			)
		);

		ok( (defined $self->ticker()), "started ticker object in waitron role" );
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
	use Reflex::Trait::Watched;

	use Test::More;

	watches counter => ( isa => 'Maybe[Counter]' );

	sub BUILD {
		my $self = shift;
		$self->counter(Counter->new());
	}

	sub on_counter_count {
		my ($self, $args) = @_;
		pass("watcher sees counter count $args->{value}/3");
		$self->counter(undef) if $args->{value} > 2;
	}
}

# Main.

my $w = Watcher->new();
Reflex->run_all();
exit;
