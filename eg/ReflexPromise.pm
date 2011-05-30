package ReflexPromise;
# vim: ts=2 sw=2 noexpandtab

use Moose;
extends 'Reflex::Base';

use Reflex::Callbacks qw(cb_promise);

has object => (
	isa => 'Reflex::Base',
	is  => 'ro',
);

has promise => (
	isa     => 'ScalarRef',
	is      => 'ro',
	default => sub { return \my $x },
);

sub BUILD {
	my $self = shift;
	$self->watch($self->object(), cb_promise($self->promise()));
}

sub next {
	my $self = shift;
	return ${$self->promise()}->next();
}

1;
