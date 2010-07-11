# Watch signals a few different ways.

use warnings;
use strict;
use lib qw(../lib);

use Reflex::Signal;
use Reflex::Callbacks qw(cb_coderef);
use ExampleHelpers qw(eg_say);

eg_say("Process $$ is waiting for SIGUSR1 and SIGUSR2.");

my $usr1 = Reflex::Signal->new(
	signal    => "USR1",
	on_signal => cb_coderef { eg_say("Got SIGUSR1.") },
);

my $usr2 = Reflex::Signal->new( signal => "USR2" );
while ($usr2->next()) {
	eg_say("Got SIGUSR2.");
}
