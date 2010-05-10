use Moose;
use Socket qw(AF_UNIX SOCK_STREAM PF_UNSPEC);
use Proxy;
use Stream;

$|=1;

# Need two sockets to test passing data back and forth.
my ($socket_1a, $socket_1b);
socketpair($socket_1a, $socket_1b, AF_UNIX, SOCK_STREAM, PF_UNSPEC) or die $!;

# Need two sockets to test passing data back and forth.
my ($socket_2a, $socket_2b);
socketpair($socket_2a, $socket_2b, AF_UNIX, SOCK_STREAM, PF_UNSPEC) or die $!;

my $p = Proxy->new(
	handle_a => $socket_1b,
	handle_b => $socket_2b,
);

my $s1 = Stream->new( handle => $socket_1a );
my $s2 = Stream->new( handle => $socket_2a );

# Write data to Socket 1a.
$s1->put("test request\n");

# Wait for it to arrive at the other end.
# Send something back.
my $e = $s2->wait();
warn $e->{name}, ": ", $e->{arg}{data};
