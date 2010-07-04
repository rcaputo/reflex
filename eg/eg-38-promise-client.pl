# A TCP echo client that looks like it's blocking when it's not.

use lib qw(../lib);
use Reflex::Timer;
use Reflex::Connector;
use Reflex::Stream;
use Reflex::Callbacks qw(cb_coderef);
use ExampleHelpers qw(eg_say);

# Run a timer so we can prove the client isn't blocking.
my $ticker = Reflex::Timer->new(
	interval    => 0.001,
	auto_repeat => 1,
	on_tick     => cb_coderef { eg_say("tick...") },
);

# Begin connecting to eg-34-tcp-server-echo.pl.
my $connector = Reflex::Connector->new(port => 12345);

# Wait for the connection to finish.
my $event = $connector->next();

# Failure?  Ok, bye.
if ($event->{name} eq "failure") {
	eg_say("connection error $event->{arg}{errnum}: $event->{arg}{errstr}");
	exit;
}

# Otherwise success.
eg_say("Connected.");

# Start a stream to work with it.
my $stream = Reflex::Stream->new(
	handle => $event->{arg}{socket},
	rd     => 1,
);

# Say hello.
$stream->put("Hello, world!\n");

# Handle a response.
$event = $stream->next();
if ($event->{name} eq "data") {
	eg_say("Got echo response: $event->{arg}{data}");
}
else {
	eg_say("Unexpected event: $event->{name}");
}

# Bored now.
exit;
