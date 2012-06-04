package Reflex::Decoder::Line;
# vim: ts=2 sw=2 noexpandtab

use Moose;
with 'Reflex::Role::Decoding';
with 'Reflex::Role::Decoding::Stream';

has newline => ( is => 'rw', isa => 'Str', default => "\x0D\x0A" );

# <doy>
#   # probably the best that's possible at the moment
#   my $header = $obj->match(qr/^(stuff)/);
#   $obj->substr(0, length($header), '');
# <doy>
#   other than converting it to a scalarref and writing the method by hand

sub shift {
	my $self = shift;

	return unless my $next = $self->messages()->[0];
	return $self->next_message() unless $next->isa(
		'Reflex::Codec::Message::Stream'
	);

	my $newline = $self->newline();
	return Reflex::Codec::Message::Incomplete->new() unless (
		my (@matches) = $next->match(qr/^(.*?)\Q$newline\E/)
	);

	if ($next->length() > length($matches[0]) + length($newline)) {
		$next->substr(0, length($matches[0]) + length($newline), '');
	}
	else {
		# Discard our empties.
		$self->next_message();
	}

	return Reflex::Codec::Message::Datagram->new(octets => $matches[0]);
}

__PACKAGE__->meta->make_immutable;

1;
