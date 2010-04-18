# A self-managing collection of objects.
package Reflex::Collection;
use Moose;
use Reflex::Callbacks qw(cb_method);

extends 'Reflex::Object';

# TODO - Validate that collected objects satsify a complementary role.

has objects => (
	is      => 'rw',
	isa     => 'HashRef[Reflex::Object]',
	default => sub { {} },
);

sub remember {
	my ($self, $object) = @_;
	$self->observe($object, shutdown => cb_method($self, "cb_forget"));
	$self->objects()->{$object} = $object;
}

sub forget {
	my ($self, $object) = @_;
	delete $self->objects()->{$object};
}

sub cb_forget {
	my ($self, $args) = @_;
	delete $self->objects()->{$args->{_sender}};
}

1;
# TODO - Document.
