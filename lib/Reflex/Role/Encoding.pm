package Reflex::Role::Encoding;
# vim: ts=2 sw=2 noexpandtab

use Reflex::Role;
use Reflex::Codec::Message;
use Reflex::Codec::Message::Eof;

role {
	my $p = shift;

	has buffer => (
		is      => 'rw',
		isa     => 'ArrayRef[Reflex::Codec::Message]',
		traits  => ['Array'],
		default => sub { [] },
		handles => {
			_push => 'push',
			_shift => 'shift',
			_has_message => 'count',
		},
	);

	method push_eof => sub {
		my $self = shift;
		$self->push(Reflex::Codec::Message::Eof->new());
	};

	method push_message => sub {
		my ($self, $message) = @_;

		if (
			$self->_has_message() and
			$message->is_combinable() and
			$self->messages()->[-1]->is_combinable()
		) {
			$self->messages()->[-1]->append($message);
			return;
		}

		$self->_push($message);
	};
};

1;
