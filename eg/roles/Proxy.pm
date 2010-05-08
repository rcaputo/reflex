package Proxy;
use Moose;
extends 'Reflex::Object';

has handle_a => ( is => 'rw', isa => 'FileHandle', required => 1 );
has handle_b => ( is => 'rw', isa => 'FileHandle', required => 1 );

with 'Readable' => {
  handle  => 'handle_a',
  active  => 1,
};

with 'Readable' => {
  handle  => 'handle_b',
  active  => 1,
};

# TODO - Next two roles should be Writable, but I haven't figured out
# the syntax for subclassing parameterized roles and overriding their
# default parameters.  "knob_suffix", "select_method" and "event"
# ought to be hidden in the defaults for a Writable role.

with 'Readable' => {
  handle        => 'handle_a',
	knob_suffix   => '_wr',
	select_method => 'select_write',
	event         => 'writable',
};

with 'Readable' => {
  handle        => 'handle_b',
	knob_suffix   => '_wr',
	select_method => 'select_write',
	event         => 'writable',
};

# TODO - put() methods.
# TODO - Write buffering to be provided by a Streamable role.

sub on_readable_handle_a_readable {
  my ($self, $arg) = @_;
	my $octet_count = sysread($self->handle_a(), my $buffer = "", 65536);
	if ($octet_count) {
		$self->emit(
			event => "handle_a_data",
			args => {
				data => $buffer,
				handle => $self->handle_a()
			},
		);
		return;
  }

	return if defined $octet_count;
	warn $!;
}

sub on_readable_handle_b_readable {
  my ($self, $arg) = @_;
	my $octet_count = sysread($self->handle_b(), my $buffer = "", 65536);
	if ($octet_count) {
		$self->emit(
			event => "handle_b_data",
			args => {
				data => $buffer,
				handle => $self->handle_b(),
			}
		);
		return;
  }

	return if defined $octet_count;
	warn $!;
}

1;
