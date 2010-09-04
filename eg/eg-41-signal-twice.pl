# Watch signals a few different ways.

use warnings;
use strict;
use lib qw(../lib);

use Reflex::Signal;
use ExampleHelpers qw(eg_say);

eg_say("Process $$ is waiting for SIGUSR1 twice.");

my $usr1_a = Reflex::Signal->new(
  signal    => "USR1",
  on_signal => sub { eg_say("Got SIGUSR1 callback.") },
);

my $usr1_b = Reflex::Signal->new( signal => "USR1" );
while ($usr1_b->next()) {
  eg_say("Got SIGUSR1 from promise.");
}
