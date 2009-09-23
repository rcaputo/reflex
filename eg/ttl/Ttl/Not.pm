# $Id$

# Logical NOT gate.
# in out
# 0  1
# 1  0

package Ttl::Not;
use Moose;
extends 'Ttl::Un';

sub on_my_change {
	my $self = shift;
	$self->out( (!$self->in()) || 0 );
}

1;
