#!/usr/bin/perl

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
    isa       => 'Delay',
    is        => 'rw',
    setup     => sub { Delay->new( interval => 1, auto_repeat => 1 ) },
  );

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

my $w = Watcher->new();
Stage->run_all();
exit;
