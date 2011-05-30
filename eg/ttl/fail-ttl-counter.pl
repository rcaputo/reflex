#!/usr/bin/env perl
# vim: ts=2 sw=2 noexpandtab

use warnings;
use strict;
use lib qw(lib);

{
	package Counter;
	use Moose;
	extends 'Reflex::Base';
	use Reflex::Trait::EmitsOnChange;
	use Reflex::Trait::Watched;

	use Ttl::FlipFlop::T;
	use Ttl::HexDecoder;

	# Create a four-bit counter using T flip-flops.
	# The counter schematic comes from Don Lancaster's _TTL Cookbook_.
	# Other sources (like www.play-hookey.com) seem to be flaky.

	watches t1      => ( isa => 'Ttl::FlipFlop::T', handles => ['clock'] );
	watches t2      => ( isa => 'Ttl::FlipFlop::T'                       );
	watches t4      => ( isa => 'Ttl::FlipFlop::T'                       );
	watches t8      => ( isa => 'Ttl::FlipFlop::T'                       );
	watches decoder => ( isa => 'Ttl::HexDecoder'                        );
	emits   out     => ( isa => 'Str'                                    );

	sub on_t1_q {
		my ($self, $args) = @_;
		$self->decoder->ones($args->{value});
	}

	sub on_t2_q {
		my ($self, $args) = @_;
		$self->decoder->twos($args->{value});
	}

	sub on_t4_q {
		my ($self, $args) = @_;
		$self->decoder->fours($args->{value});
	}

	sub on_t8_q {
		my ($self, $args) = @_;
		$self->decoder->eights($args->{value});
	}

	sub on_decoder_out {
		my ($self, $args) = @_;
		$self->out($args->{value});
	}

	sub on_t1_not_q {
		my ($self, $args) = @_;
		$self->t2->clock($args->{value});
	}

	sub on_t2_not_q {
		my ($self, $args) = @_;
		$self->t4->clock($args->{value});
	}

	sub on_t4_not_q {
		my ($self, $args) = @_;
		$self->t8->clock($args->{value});
	}

	sub BUILD {
		my $self = shift;
		$self->t1( Ttl::FlipFlop::T->new() );
		$self->t2( Ttl::FlipFlop::T->new() );
		$self->t4( Ttl::FlipFlop::T->new() );
		$self->t8( Ttl::FlipFlop::T->new() );
		$self->decoder( Ttl::HexDecoder->new() );
	}
}

### An object to drive the clock and display its output.

{
	package Driver;
	use Moose;
	extends 'Reflex::Base';
	use Reflex::Interval;
	use Reflex::Trait::Watched;

	watches counter  => ( isa => 'Counter' );
	watches clock    => ( isa => 'Reflex::Interval' );

	sub BUILD {
		my $self = shift;
		$self->counter( Counter->new() );
		$self->clock( Reflex::Interval->new( interval => 1, auto_repeat => 1 ) );
	}

	sub on_clock_tick {
		my $self = shift;
		$self->counter->clock(1);
		$self->counter->clock(0);
	}

	sub on_counter_out {
		my ($self, $args) = @_;
		print "Counter: $args->{value}\n";
	}
}

### Main.

exit Driver->new()->run_all();
