# $Id$

# Logical AND gate.
# a b out
# 0 0 0
# 1 0 0
# 0 1 0
# 1 1 1

package Ttl::And;
use Moose;
extends 'Ttl::Bin';

sub on_my_change {
	my $self = shift;
	warn 999;
	$self->out( ($self->a() && $self->b()) || 0 );
}

1;
