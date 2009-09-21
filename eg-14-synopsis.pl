#!/usr/bin/env perl

use warnings;
use strict;
use lib qw(lib);

{
  package App;
  use Moose;
  extends 'Reflex::Object';
  use Reflex::Timer;

  has ticker => (
    isa     => 'Reflex::Timer',
    is      => 'rw',
    setup   => { interval => 1, auto_repeat => 1 },
    traits  => [ 'Reflex::Trait::Observer' ],
  );

  sub on_ticker_tick {
    print "tick at ", scalar(localtime), "...\n";
  }
}

exit App->new()->run_all();
