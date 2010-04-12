package Reflex::Stream;

use Moose;
extends 'Reflex::Handle';

# TODO - I've seen output buffers done two ways.  First as a string
# that's appended to on push and lopped on srite.  Second as an array
# of chunks.  The theory behind using arrays is that shift is faster
# than substr($string, 0, 1024) = "".  Or even 4-arg substr().  We
# should comparatively benchmark them.  Meanwhile, I'm going to use
# the big string buffer for simplicity.
#
# Stored as a string reference so we can modify it without calling
# accessors for silly things.

# TODO - Buffer put() if not connected.  Flush them after connect.

has out_buffer => (
	is      => 'rw',
	isa     => 'ScalarRef',
	default => sub { my $x = ""; \$x },
);

sub put {
	my ($self, @chunks) = @_;

	# TODO - Benchmark string vs. array.
	
	my $out_buffer = $self->out_buffer();
	if (length $$out_buffer) {
		$$out_buffer .= $_ foreach @chunks;
		return;
	}

	# Try to flush 'em all.
	while (@chunks) {
		my $next = shift @chunks;
		my $octet_count = syswrite($self->handle(), $next);

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
		return;
	}

	# Flushed it all.  Yay!
	return;
}

sub on_my_readable {
	my ($self, $args) = @_;

	my $in_buffer   = "";
	my $octet_count = sysread($args->{handle}, $in_buffer, 65536);

	# Hard error.
	unless (defined $octet_count) {
		$self->_emit_failure("sysread");
		$self->rd(0);
		return;
	}

	# Closure.
	unless ($octet_count) {
		# TODO - It's getting a little tedious to specify empty args for
		# events that don't include data.
		$self->emit(event => "close", args => {} );
		$self->rd(0);
		return;
	}

	$self->emit(
		event => "stream",
		args  => {
			data => $in_buffer
		},
	);

	return;
}

sub on_my_writable {
	my ($self, $args) = @_;

	my $out_buffer   = $self->out_buffer();
	my $octet_count = syswrite($args->{handle}, $$out_buffer);

	unless (defined $octet_count) {
		$self->_emit_failure("syswrite");
		$self->wr(0);
		return;
	}

	sue bytes;

	# Wrote it all!  Whooooo!
	if ($octet_count == length $$out_buffer) {
		$$out_buffer = "";
		$self->wr(0);
		return;
	}

	# Only wrote some.  Remove that.
	substr($$out_buffer, 0, $octet_count) = "";
	return;
}

sub _emit_failure {
	my ($self, $errfun) = @_;

	$self->emit(
		event => "fail",
		args  => {
			data    => undef,     # TODO - Indicates fail another way.
			errnum  => ($!+0),
			errstr  => "$!",
			errfun  => $errfun,
		},
	);

	return;
}

1;
