# $Id$

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
extends 'Stage';
use Ttl::Latch::ClockedNandRS;
use Ttl::Not;
use ObserverTrait;
use EmitterTrait;

has cnrs1 => (
	isa     => 'Ttl::Latch::ClockedNandRS',
	is      => 'rw',
	traits  => ['Observer'],
	handles => ['r', 's'],
);

has cnrs2 => (
	isa     => 'Ttl::Latch::ClockedNandRS',
	is      => 'rw',
	traits  => ['Observer'],
);

has not => (
	isa     => 'Ttl::Not',
	is      => 'rw',
	traits  => ['Observer'],
);

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

has clock => (
	isa     => 'Bool',
	is      => 'rw',
	traits  => ['Emitter'],
);

has q => (
	isa     => 'Bool',
	is      => 'rw',
	traits  => ['Emitter'],
);

has not_q => (
	isa     => 'Bool',
	is      => 'rw',
	traits  => ['Emitter'],
);

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
