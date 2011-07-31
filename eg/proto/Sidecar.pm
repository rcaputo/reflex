package Sidecar;
# vim: ts=2 sw=2 noexpandtab

# "Sidecar" is what I call a subprocess that handles a particular
# object.  The analogy is to motorcycle sidecars.

use warnings;
use strict;

use Storable qw(nfreeze thaw);

sub BUILD {
	use IPC::Run qw(start);
	use Symbol qw(gensym);

	my ($fh_in, $fh_out, $fh_err) = (gensym(), gensym(), gensym());

	my $ipc_run = start(
		$cmd,
		'<pipe', $fh_in,
		'>pipe', $fh_out,
		'2>pipe', $fh_err,
	) or die "IPC::Run start() failed: $? ($!)";

	return($ipc_run, $fh_in, $fh_out, $fh_err);
}

sub _sidecar_drive {
	my $self = shift;

	my $buffer = "";
	my $read_length;

	binmode(STDIN);
	binmode(STDOUT);
	select STDOUT; $| = 1;

	use bytes;

	while (1) {
		if (defined $read_length) {
			if (length($buffer) >= $read_length) {
				my $request = thaw(substr($buffer, 0, $read_length, ""));
				$read_length = undef;

				my ($request_id, $context, $method, @args) = @$request;

				my $streamable;

				if ($context eq "array") {
					my (@return) = eval { $self->$method(@args); };
					$streamable = nfreeze( [ $request_id, $context, $@, @return ] );
				}
				elsif ($context eq "scalar") {
					my $return = eval { $self->$method(@args); };
					$streamable = nfreeze( [ $request_id, $context, $@, $return ] );
				}
				else {
					eval { $self->$method(@args); undef; };
					$streamable = nfreeze( [ $request_id, $context, $@ ] );
				}

				my $stream = length($streamable) . chr(0) . $streamable;

				my $octets_wrote = syswrite(STDOUT, $stream);
				die $! unless $octets_wrote == length($stream);

				next;
			}
		}
		elsif ($buffer =~ s/^(\d+)\0//) {
			$read_length = $1;
			next;
		}

		my $octets_read = sysread(STDIN, $buffer, 4096, length($buffer));
		last unless $octets_read;
	}

	exit 0;
}

1;
