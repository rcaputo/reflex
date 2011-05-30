# vim: ts=2 sw=2 noexpandtab

# Logical OR gate.
# a b out
# 0 0 0
# 1 0 1
# 0 1 1
# 1 1 1

package Ttl::Or;
use Moose;
extends 'Ttl::Bin';

sub on_my_change {
	my $self = shift;
	$self->out( ($self->a() || $self->b()) || 0 );
}

1;
