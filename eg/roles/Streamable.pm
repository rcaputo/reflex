package Streamable;
use MooseX::Role::Parameterized;

use Scalar::Util qw(weaken);

parameter handle => (
	isa     => 'Str',
	default => 'handle',
);

role {
	my $p = shift;

	my $h = $p->handle();

	with Readable => {
		handle  => $h,
		knob    => "${h}_rd",
		active  => 1,
	};

	with Writable => {
		handle  => $h,
		knob    => "${h}_wr",
	};

	has out_buffer => (
		is      => 'rw',
		isa     => 'ScalarRef',
		default => sub { my $x = ""; \$x },
	);

	method "on_" . $p->handle() . "_readable" => sub {
		my ($self, $arg) = @_;

		my $octet_count = sysread($arg->{handle}, my $buffer = "", 65536);
		if ($octet_count) {
			$self->emit(
				event => $p->handle() . "_data",
				args => {
					data => $buffer,
					handle => $arg->{handle},
				},
			);
			return;
		}

		return if defined $octet_count;
		warn $!;
	};

	method "put_$h" => sub {
		my ($self, @chunks) = @_;

		# TODO - Benchmark string vs. array.
		
		my $out_buffer = $self->out_buffer();
		if (length $$out_buffer) {
			$$out_buffer .= $_ foreach @chunks;
			return length $$out_buffer;
		}

		# Try to flush 'em all.
		while (@chunks) {
			my $next = shift @chunks;
			my $octet_count = syswrite($self->$h(), $next);

			# Hard error.
			unless (defined $octet_count) {
				$self->_emit_failure("syswrite");
				return;
			}

			use bytes;

			# Wrote it all!  Whooooo!
			next if $octet_count == length $next;

			# Wrote less than all.  Save the rest, and turn on write
			# multiplexing.

			$$out_buffer = substr($next, $octet_count);
			$$out_buffer .= $_ foreach @chunks;
			$self->wr(1);
			return length $$out_buffer;
		}

		# Flushed it all.  Yay!
		return 0;
	};
};

1;
