package Reflex::Event::Socket;

use Moose;
extends 'Reflex::Event::FileHandle';

has peer => (
	is      => 'ro',
	isa     => 'Str',
	lazy    => 1,
	default => sub {
		my $self = shift();
		return getpeername $self->handle();
	},
);

__PACKAGE__->make_event_cloner;
__PACKAGE__->meta->make_immutable;

1;
