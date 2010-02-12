package Reflex::Callback::CodeRef;

use Moose;
extends 'Reflex::Callback';

has code_ref => (
	is => 'ro',
	isa => 'CodeRef',
	required => 1,
);

sub deliver {
	my $self = shift;
	$self->code_ref()->(@_);
}


1;
