package Reflex::Callback::Method;

use Moose;
extends 'Reflex::Callback';

has object => (
	is        => 'ro',
	isa       => 'Object',
	weak_ref  => 1,
);

has method_name => (
	is        => 'ro',
	isa       => 'Str',
	required  => 1,
);

sub deliver {
	my $self = shift;
	my $method_name = $self->method_name();
	$self->object()->$method_name(@_);
}

1;
