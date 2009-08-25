# $Id$

# RS Nor latch.
# 
# R ------a\
#           (NOR1)-+--- Q
#     +---b/       |
#     |            |
#     +--------------+
#                  | |
#     +------------+ |
#     |              |
#     +---a\         |  _
#           (NOR2)---+- Q
# S ------b/

package Ttl::Latch::NorRS;
use Moose;
extends 'Stage';
use Ttl::Nor;
use ObserverTrait;
use EmitterTrait;

has nor_r => (
	isa     => 'Ttl::Nor',
	is      => 'rw',
	traits  => ['Observer'],
	handles => { r => 'a' },
);

has nor_s => (
	isa     => 'Ttl::Nor',
	is      => 'rw',
	traits  => ['Observer'],
	handles => { s => 'b' },
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

sub on_nor_s_out {
	my ($self, $args) = @_;
	$self->not_q($args->{value});
	$self->nor_r()->b($args->{value});
}

sub on_nor_r_out {
	my ($self, $args) = @_;
	$self->q($args->{value});
	$self->nor_s()->a($args->{value});
}

sub BUILD {
	my $self = shift;
	$self->nor_r( Ttl::Nor->new() );
	$self->nor_s( Ttl::Nor->new() );
	$self->r(0);
	$self->s(0);
}

1;
