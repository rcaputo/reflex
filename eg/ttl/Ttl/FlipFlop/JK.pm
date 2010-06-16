# $Id$

# JK flip-flop.
#
# preset -----------------+
#                          \
#                           \
# j ----------\              \
#              (nand1)--------(trinand1)---+-- q
#          +--/              /             |
#          |                +------------+ |
# clock ---+                             | |
#          |                +------------|-+
#          +--\              \           |
#              (nand2)--------(trinand2)-+---- _q
# k ----------/              /
#                           /
#                          /
# clear ------------------+

package Ttl::FlipFlop::JK;
use Moose;
extends 'Reflex::Object';
use Ttl::Latch::ClockedNandRS;
use Reflex::Trait::Observed;
use Reflex::Trait::Emitter;

has nand_j => (
	isa     => 'Ttl::Nand',
	is      => 'rw',
	traits  => ['Reflex::Trait::Observed'],
	handles => { j => 'a' },
);

has nand_k => (
	isa     => 'Ttl::Nand',
	is      => 'rw',
	traits  => ['Reflex::Trait::Observed'],
	handles => { k => 'b' },
);

has trinand_preset => (
	isa     => 'Ttl::TriNand',
	is      => 'rw',
	traits  => ['Reflex::Trait::Observed'],
	handles => { preset => 'a' },
);

has trinand_clear => (
	isa     => 'Ttl::TriNand',
	is      => 'rw',
	traits  => ['Reflex::Trait::Observed'],
	handles => { clear => 'c' },
);

has q => (
	isa     => 'Bool',
	is      => 'rw',
	traits  => ['Reflex::Trait::Emitter'],
);

has not_q => (
	isa     => 'Bool',
	is      => 'rw',
	traits  => ['Reflex::Trait::Emitter'],
);

has clock => (
	isa     => 'Bool',
	is      => 'rw',
	traits  => ['Reflex::Trait::Emitter'],
);

sub BUILD {
	my $self = shift;
	$self->nand_j( Ttl::Nand->new() );
	$self->nand_k( Ttl::Nand->new() );
	$self->trinand_preset( Ttl::TriNand->new() );
	$self->trinand_clear( Ttl::TriNand->new() );
	$self->preset(1);
	$self->clear(1);
	$self->j(0);
	$self->k(0);
	$self->clock(0);
}

sub on_my_clock {
	my ($self, $args) = @_;
	$self->nand_j->b($args->{value});
	$self->nand_k->a($args->{value});
}

sub on_nand_j_out {
	my ($self, $args) = @_;
	$self->trinand_preset->b($args->{value});
}

sub on_nand_k_out {
	my ($self, $args) = @_;
	$self->trinand_clear->b($args->{value});
}

sub on_trinand_preset_out {
	my ($self, $args) = @_;
	$self->q($args->{value});
	$self->trinand_clear->a($args->{value});
}

sub on_trinand_clear_out {
	my ($self, $args) = @_;
	$self->not_q($args->{value});
	$self->trinand_preset->c($args->{value});
}

1;
