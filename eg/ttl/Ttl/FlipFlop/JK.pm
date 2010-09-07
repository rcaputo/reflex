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
extends 'Reflex::Base';
use Ttl::Latch::ClockedNandRS;

observes nand_j => (
	isa     => 'Ttl::Nand',
	handles => { j => 'a' },
);

observes nand_k => (
	isa     => 'Ttl::Nand',
	handles => { k => 'b' },
);

observes trinand_preset => (
	isa     => 'Ttl::TriNand',
	handles => { preset => 'a' },
);

observes trinand_clear => (
	isa     => 'Ttl::TriNand',
	handles => { clear => 'c' },
);

emits q => (
	isa     => 'Bool',
);

emits not_q => (
	isa     => 'Bool',
);

emits clock => (
	isa     => 'Bool',
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
