#!/usr/bin/env perl

# Use Reflex without Moose.  For people who don't like Moose.

use warnings;
use strict;
use lib qw(../lib);

{
  package App;
  use Reflex::Object;
  use Reflex::Timer;
  use base qw(Reflex::Object);

  sub BUILD {
    my $self = shift;

    $self->{ticker} = Reflex::Timer->new(
      interval => 1,
      auto_repeat => 1,
    );

    $self->observe_role(
      observed => $self->{ticker},
      role     => "ticker",
    );
  }

  sub on_ticker_tick {
    print "tick at ", scalar(localtime), "...\n";
  }
}

exit App->new()->run_all();
