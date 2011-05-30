package Reflex::Role::Decoding::Stream;
# vim: ts=2 sw=2 noexpandtab

use Reflex::Role;
use Reflex::Codec::Message::Stream;
use Reflex::Codec::Message::Eof;

role {
	my $p = shift;

	method push_stream => sub {
		my $self = shift;

		return unless @_;
		return unless length(my $data = join "", @_);

		if (
			$self->has_message() and
			$self->messages()->[-1]->is_combinable()
		) {
			$self->messages()->[-1]->append($data);
			return;
		}

		$self->push_message(
			Reflex::Codec::Message::Stream->new( octets => $data )
		);

		return;
	};

	method push_eof => sub {
		my $self = shift;

		# Already got one, thanks.
		return if (
			$self->has_message() and
			$self->messages()->[-1]->isa('Reflex::Codec::Message::Eof')
		);

		$self->push_message(Reflex::Codec::Message::Eof->new());

		undef;
	};
};

1;

