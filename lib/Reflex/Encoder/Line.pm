package Reflex::Encoder::Line;
# vim: ts=2 sw=2 noexpandtab

use Moose;
with 'Reflex::Role::Encoding';
use Reflex::Codec::Message;

use Scalar::Util qw(blessed);

has newline => ( is => 'rw', isa => 'Str', default => "\x0D\x0A" );

# Data translation is lazy.
# Translation happens when data is shifted off the encoding buffer.
# The original data is available as long as possible.
# Protocol swapping requires this.


sub push_data {
	my $self = shift;

	if (
		$self->_has_messages() and
		$self->messages()->[-1]->is_combinable()
	) {
		$self->messages()->[-1]->append_data(@_);
		return;
	}

	$self->push_message(Reflex::Codec::Message::Stream->new(data => $_))
		foreach @_;

	return;
}

sub shift {
	my $self = shift;

	return unless defined(my $next = $self->_shift());

	if (defined(my $next_data = $next->data())) {
		$next->data($next_data . $self->newline());
	}

	return $next;
}

__PACKAGE__->meta->make_immutable;

1;
