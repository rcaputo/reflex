package Reflex::Sender;

#ABSTRACT: The _sender access object

use Moose;
use Scalar::Util qw(weaken);

has senders => (
	is => 'ro',
	isa => 'ArrayRef',
	traits => ['Array'],
	default => sub { [] },
	handles => {
		'get_first_emitter' => [ 'get', 0  ],
		'get_last_emitter'  => [ 'get', -1 ],
		'get_all_emitters'  => 'elements',
	}
);

sub push_emitter {
	my ($self, $item) = @_;
	push(@{$self->senders}, $item);
	weaken($self->senders->[-1]);
}

no Moose;
__PACKAGE__->meta->make_immutable;

1;

__END__

=head1 NAME

Reflex::Sender - API to access the objects an event has passed through

=head1 DESCRIPTION

Reflex::Sender provides a simple API to gain access to the sources of emitted
events.

=head1 Public Methods

=head2 get_first_emitter

The original source of an event can be accessed with this method

=head2 get_last_emitter

The final emitter (the one the watcher was explicitly watching) can be
accessed with this method

=head2 get_all_emitters

If the first nor the last are insufficient, the whole stack of emitters can be
accessed (returning a list) using this method

=cut
