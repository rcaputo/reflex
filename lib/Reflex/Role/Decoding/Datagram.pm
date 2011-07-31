package Reflex::Role::Decoding::Datagram;
# vim: ts=2 sw=2 noexpandtab

use Reflex::Role;
use Reflex::Codec::Message::Datagram;

role {
	my $p = shift;

	method push_datagram => sub {
		my $self = shift;

		return unless @_;

		$self->push_message(
			Reflex::Codec::Message::Datagram->new( octets => $_ )
		) foreach @_;

		return;
	};
};

1;
