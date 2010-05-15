package Streamable;
use MooseX::Role::Parameterized;
use EmitHelper qw(default_emit);

use Scalar::Util qw(weaken);

parameter handle => (
	isa     => 'Str',
	default => 'handle',
);

parameter cb_data => (
	isa       => 'Str',
	default   => sub {
		my $self = shift;
		"on_" . $self->handle() . "_data";
	},
	lazy      => 1,
);

parameter cb_error => (
	isa       => 'Str',
	default   => sub {
		my $self = shift;
		"on_" . $self->handle() . "_error";
	},
	lazy      => 1,
);

role {
	my $p = shift;

	my $h         = $p->handle();
	my $cb_data   = $p->cb_data();
	my $cb_error  = $p->cb_error();

	with Readable => {
		handle  => $h,
		active  => 1,
	};

	with Writable => {
		handle  => $h,
	};

	has out_buffer => (
		is      => 'rw',
		isa     => 'ScalarRef',
		default => sub { my $x = ""; \$x },
	);

	method "on_${h}_readable" => sub {
		my ($self, $arg) = @_;

		my $octet_count = sysread($arg->{handle}, my $buffer = "", 65536);
		if ($octet_count) {
			$self->$cb_data({ data => $buffer });
			return;
		}

		return if defined $octet_count;

		$self->cb_error(
			{
				errnum => ($! + 0),
				errstr => "$!",
				errfun => "sysread",
			}
		);
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
				$self->$cb_error(
					{
						errnum => ($! + 0),
						errstr => "$!",
						errfun => "syswrite",
					}
				);
				return;
			}

			use bytes;

			# Wrote it all!  Whooooo!
			next if $octet_count == length $next;

			# Wrote less than all.  Save the rest, and turn on write
			# multiplexing.
			$$out_buffer = substr($next, $octet_count);
			$$out_buffer .= $_ foreach @chunks;

			$self->resume_handle_writable();
			return length $$out_buffer;
		}

		# Flushed it all.  Yay!
		return 0;
	};

	# Default callbacks that re-emit their parameters.
	method default_emit($cb_data,  "data");
	method default_emit($cb_error, "error");
};

1;
