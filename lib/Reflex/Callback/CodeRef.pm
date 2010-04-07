package Reflex::Callback::CodeRef;

use Moose;
extends 'Reflex::Callback';

use POE::Kernel; # for $poe_kernel

has code_ref => (
	is => 'ro',
	isa => 'CodeRef',
	required => 1,
);

sub deliver {
	my ($self, $event, $arg) = @_;
	$self->code_ref()->($arg);
}

1;
