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
extends 'Reflex::Base';
use Ttl::Nand;

use Reflex::Trait::Observed;
use Reflex::Trait::EmitsOnChange;

observes nand_r => ( isa => 'Ttl::Nand', handles => { r => 'b' } );
observes nand_s => ( isa => 'Ttl::Nand', handles => { s => 'a' } );
emits    q      => ( isa => 'Bool'                               );
emits    not_q  => ( isa => 'Bool'                               );

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
