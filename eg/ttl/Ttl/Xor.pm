# vim: ts=2 sw=2 noexpandtab

# Logical XOR gate.
# a b out
# 0 0 0
# 1 0 1
# 0 1 1
# 1 1 0

package Ttl::Xor;
use Moose;
extends 'Ttl::Bin';

sub on_my_change {
	my $self = shift;
	$self->out( (($self->a()||0) != ($self->b()||0)) || 0 );
}

1;
