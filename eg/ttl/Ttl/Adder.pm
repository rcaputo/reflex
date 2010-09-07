# $Id$

# Full adder integrated circuit.  Not clocked.
#
#   A --------+---a\
#             |     (XOR ab)--+-a\
#   B -----+------b/          |   (XOR cin)----- Sum
#          |  |           +-----b/
#          |  |           |   |
#   Cin ------------------+   |
#          |  |           |   +-a\
#          |  |           |       (AND cin)-a\
#          |  +a\         +-----b/            (OR)-- Cout
#          |     (AND ab)-------------------b/
#          +---b/
#
# A + B + Cin = Sum + Cout
# 0   0   0     0     0
# 1   0   0     1     0
# 0   1   0     1     0
# 1   1   0     0     1
# 0   0   1     1     0
# 1   0   1     0     1
# 0   1   1     0     1
# 1   1   1     1     1

package Ttl::Adder;
use Moose;
extends 'Reflex::Base';

use Ttl::Xor;
use Ttl::And;
use Ttl::Or;

emits      a       => ( isa => 'Bool'     );
emits      b       => ( isa => 'Bool'     );
emits      cin     => ( isa => 'Bool'     );
observes   xor_ab  => ( isa => 'Ttl::Xor' );
observes   xor_cin => ( isa => 'Ttl::Xor' );
observes   and_ab  => ( isa => 'Ttl::And' );
observes   and_cin => ( isa => 'Ttl::And' );
observes   or_cout => ( isa => 'Ttl::Or'  );
emits      sum     => ( isa => 'Bool'     );
emits      cout    => ( isa => 'Bool'     );

sub on_my_a {
	my ($self, $args) = @_;
	$self->xor_ab()->a($args->{value});
	$self->and_ab()->a($args->{value});
}

sub on_my_b {
	my ($self, $args) = @_;
	$self->xor_ab()->b($args->{value});
	$self->and_ab()->b($args->{value});
}

sub on_my_cin {
	my ($self, $args) = @_;
	$self->xor_cin()->b($args->{value});
	$self->and_cin()->b($args->{value});
}

sub on_xor_ab_out {
	my ($self, $args) = @_;
	$self->xor_cin()->a($args->{value});
	$self->and_cin()->a($args->{value});
}

sub on_xor_cin_out {
	my ($self, $args) = @_;
	$self->sum($args->{value});
}

sub on_and_ab_out {
	my ($self, $args) = @_;
	$self->or_cout->b($args->{value});
}

sub on_and_cin_out {
	my ($self, $args) = @_;
	$self->or_cout->a($args->{value});
}

sub on_or_cout_out {
	my ($self, $args) = @_;
	$self->cout($args->{value});
}

sub BUILD {
	my $self = shift;
	$self->xor_ab( Ttl::Xor->new() );
	$self->xor_cin( Ttl::Xor->new() );
	$self->and_ab( Ttl::And->new() );
	$self->and_cin( Ttl::And->new() );
	$self->or_cout( Ttl::Or->new() );
}

1;
