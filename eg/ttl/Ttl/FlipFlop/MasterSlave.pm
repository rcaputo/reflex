# vim: ts=2 sw=2 noexpandtab

# Edge-triggered RS (master/slave) filp-flop.
#
# S ---------         --         --- Q
#            \      Q/  \S      /
#             (CNRS1)    (CNRS2)
#            /   |  _\  /R  |   \    _
# R ---------    |  Q --    |    --- Q
#                |          |
# Clk -+-(NOT)---+          |
#      |                    |
#      +--------------------+

package Ttl::FlipFlop::MasterSlave;
use Moose;
extends 'Reflex::Base';
use Ttl::Latch::ClockedNandRS;
use Ttl::Not;

use Reflex::Trait::EmitsOnChange;
use Reflex::Trait::Watched;

watches cnrs1 => (
	isa => 'Ttl::Latch::ClockedNandRS',
	handles => ['r', 's'],
);

watches cnrs2 => ( isa => 'Ttl::Latch::ClockedNandRS' );
watches not   => ( isa => 'Ttl::Not'                  );

sub BUILD {
	my $self = shift;
	$self->cnrs1( Ttl::Latch::ClockedNandRS->new() );
	$self->cnrs2( Ttl::Latch::ClockedNandRS->new() );
	$self->not( Ttl::Not->new() );

	$self->r(0);
	$self->s(0);
	$self->clock(1);
	$self->clock(0);
}

emits clock => ( isa => 'Bool' );
emits q     => ( isa => 'Bool' );
emits not_q => ( isa => 'Bool' );

sub on_my_clock {
	my ($self, $args) = @_;
	$self->not->in($args->{value});
	$self->cnrs2->clock($args->{value});
}

sub on_cnrs1_q {
	my ($self, $args) = @_;
	$self->cnrs2->s($args->{value});
}

sub on_cnrs1_not_q {
	my ($self, $args) = @_;
	$self->cnrs2->r($args->{value});
}

sub on_not_out {
	my ($self, $args) = @_;
	$self->cnrs1->clock($args->{value});
}

sub on_cnrs2_q {
	my ($self, $args) = @_;
	$self->q($args->{value});
}

sub on_cnrs2_not_q {
	my ($self, $args) = @_;
	$self->not_q($args->{value});
}

1;
