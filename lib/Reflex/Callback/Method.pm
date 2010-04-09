package Reflex::Callback::Method;

use Moose;
extends 'Reflex::Callback';

has method_name => (
	is        => 'ro',
	isa       => 'Str',
	required  => 1,
);

sub deliver {
	my ($self, $event, $arg) = @_;
	my $method_name = $self->method_name();
	$self->object()->$method_name($arg);
}

1;
