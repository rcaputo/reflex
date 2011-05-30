package Reflex::Role::Decoding;
# vim: ts=2 sw=2 noexpandtab

use Reflex::Role;
use Reflex::Codec::Message::Stream;
use Reflex::Codec::Message::Datagram;

role {
	my $p = shift;

	has messages => (
		is      => 'rw',
		isa     => 'ArrayRef[Reflex::Codec::Message]',
		traits  => ['Array'],
		default => sub { [] },
		handles => {
			push_message => 'push',
			has_message => 'count',
			next_message => 'shift',
		},
	);
};

1;
