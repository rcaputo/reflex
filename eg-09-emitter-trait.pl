#!/usr/bin/perl

# Objects may emit events when their members are changed.

{
	package Counter;
	use Moose;
	extends 'Stage';
	use Delay;
	use ObserverTrait;
	use EmitterTrait;

	has count   => (
		traits    => ['Emitter'],
		isa       => 'Int',
		is        => 'rw',
		default   => 0,
	);

	has ticker  => (
		traits    => ['Observer'],
		isa       => 'Delay|Undef',
		is        => 'rw',
	);

	sub BUILD {
		my $self = shift;

		$self->ticker(
			Delay->new(
				interval    => 1,
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
	extends 'Stage';

	has counter => (
		traits  => ['Observer'],
		isa     => 'Counter',
		is      => 'rw',
	);

	sub BUILD {
		my $self = shift;
		$self->counter(Counter->new());
	}

	sub on_counter_count {
		my ($self, $args) = @_;
		warn "Watcher sees counter count: $args->{value}\n";
	}
}

my $w = Watcher->new();
Stage->run_all();
exit;
