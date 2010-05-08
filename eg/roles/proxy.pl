use Moose;
use POE::Pipe::TwoWay;
use Socket qw(AF_UNIX SOCK_STREAM PF_UNSPEC);
use Proxy;

# Need two sockets to test passing data back and forth.
my ($socket_a, $socket_b);
socketpair($socket_a, $socket_b, AF_UNIX, SOCK_STREAM, PF_UNSPEC) or die $!;

my $p = Proxy->new(
	handle_a => $socket_a,
	handle_b => $socket_b,
);

# Write test data to one end of the proxy.
print $socket_a "test request\n";

# Wait for it to arrive at the other end.
# Send something back.
{
	my $e = $p->wait();
	warn $e->{name}, ": ", $e->{arg}{data};
	print {$e->{arg}{handle}} "test response\n";
}

# Wait for it to arrive back.
my $e = $p->wait();
warn $e->{name}, ": ", $e->{arg}{data};
