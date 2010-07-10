package Reflex::Role::Writing;
use Reflex::Role;
use Reflex::Util::Methods qw(emit_an_event emit_and_stopped method_name);

attribute_parameter handle        => "handle";
method_parameter    method_put    => qw( put handle _ );
method_parameter    method_flush  => qw( on handle writable );
callback_parameter  cb_error      => qw( on handle error );

role {
	my $p = shift;

	my $h             = $p->handle();
	my $cb_error      = $p->cb_error();
	my $method_flush  = $p->method_flush();

	requires $cb_error;

	has out_buffer => (
		is      => 'rw',
		isa     => 'ScalarRef',
		default => sub { my $x = ""; \$x },
	);

	my $resume_writable = "resume_${h}_writable";
	my $pause_writable  = "pause_${h}_writable";

	method $method_flush => sub {
		my ($self, $arg) = @_;

		my $out_buffer = $self->out_buffer();
		my $octet_count = syswrite($self->$h(), $$out_buffer);

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

		# Remove what we wrote.
		substr($$out_buffer, 0, $octet_count, "");

		# Pause writes if it all was flushed.
		return if length $$out_buffer;
		$self->$pause_writable();
		return;
	};

	method $p->method_put() => sub {
		my ($self, @chunks) = @_;

		# TODO - Benchmark string vs. array buffering.

		use bytes;

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

			# Wrote it all!  Whooooo!
			next if $octet_count == length $next;

			# Wrote less than all.  Save the rest, and turn on write
			# multiplexing.
			$$out_buffer = substr($next, $octet_count);
			$$out_buffer .= $_ foreach @chunks;

			$self->$resume_writable();
			return length $$out_buffer;
		}

		# Flushed it all.  Yay!
		return 0;
	};
};

1;
