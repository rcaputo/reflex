# $Id$

# RS Nand latch.
# 
# S ------a\
#           (NAND1)-+--- Q
#     +---b/        |
#     |             |
#     +---------------+
#                   | |
#     +-------------+ |
#     |               |
#     +---a\          |  _
#           (NAND2)---+- Q
# R ------b/

package Ttl::Latch::NandRS;
use Moose;
extends 'Reflex::Object';
use Ttl::Nand;
use Reflex::Trait::Observed;
use Reflex::Trait::EmitsOnChange;

has nand_r => (
	isa     => 'Ttl::Nand',
	is      => 'rw',
	traits  => ['Reflex::Trait::Observed'],
	handles => { r => 'b' },
);

has nand_s => (
	isa     => 'Ttl::Nand',
	is      => 'rw',
	traits  => ['Reflex::Trait::Observed'],
	handles => { s => 'a' },
);

has q => (
	isa     => 'Bool',
	is      => 'rw',
	traits  => ['Reflex::Trait::EmitsOnChange'],
);

has not_q => (
	isa     => 'Bool',
	is      => 'rw',
	traits  => ['Reflex::Trait::EmitsOnChange'],
);

sub on_nand_s_out {
	my ($self, $args) = @_;
	$self->q($args->{value});
	$self->nand_r()->a($args->{value});
}

sub on_nand_r_out {
	my ($self, $args) = @_;
	$self->not_q($args->{value});
	$self->nand_s()->b($args->{value});
}

sub BUILD {
	my $self = shift;
	$self->nand_r( Ttl::Nand->new() );
	$self->nand_s( Ttl::Nand->new() );
	$self->r(0);
	$self->s(0);
}

1;
