package ReflexPromise;

use Moose;
extends 'Reflex::Object';

use Reflex::Callbacks qw(cb_promise);

has object => (
	isa => 'Reflex::Object',
	is  => 'ro',
);

has promise => (
	isa     => 'ScalarRef',
	is      => 'ro',
	default => sub { return \my $x },
);

sub BUILD {
	my $self = shift;
	$self->observe($self->object(), cb_promise($self->promise()));
}

sub wait {
	my $self = shift;
	return ${$self->promise()}->wait();
}

1;
