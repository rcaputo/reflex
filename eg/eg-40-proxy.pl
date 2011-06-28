# vim: ts=2 sw=2 noexpandtab
use lib qw(../lib);

use Moose;
use Socket qw(AF_UNIX SOCK_STREAM PF_UNSPEC);
use Proxy;
use Reflex::Stream;

# Socket pair 1.  Writes to either end are readable at the other.
my ($socket_1a, $socket_1b);
socketpair($socket_1a, $socket_1b, AF_UNIX, SOCK_STREAM, PF_UNSPEC) or die $!;

# Socket pair 2.  Writes to either end are readable at the other.
my ($socket_2a, $socket_2b);
socketpair($socket_2a, $socket_2b, AF_UNIX, SOCK_STREAM, PF_UNSPEC) or die $!;

# Proxy.  Data appearing at either end is written to the other.
my $p = Proxy->new(
	client => $socket_1b,
	server => $socket_2b,
);

my $s1 = Reflex::Stream->new( handle => $socket_1a );
my $s2 = Reflex::Stream->new( handle => $socket_2a );

# Write data to Socket 1a.
# It will appear on Socket 1b, via the socketpair.
# Proxy will write it to Socket 2b.
# The data will emerge on Socket 2a, via the other socketpair.

$s1->put("test request\n");

# Wait for it to arrive on Stream 2 (socket 2a).
my $e = $s2->next();
warn "Got: ", $e->{name}, ": ", $e->{arg}{data};
