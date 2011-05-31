# vim: ts=2 sw=2 noexpandtab

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
extends 'Reflex::Base';
use Ttl::Nor;

use Reflex::Trait::Watched qw(watches);
use Reflex::Trait::EmitsOnChange qw(emits);

watches nor_r => ( isa => 'Ttl::Nor', handles => { r => 'a' } );
watches nor_s => ( isa => 'Ttl::Nor', handles => { s => 'b' } );
emits   q     => ( isa => 'Bool'                              );
emits   not_q => ( isa => 'Bool'                              );

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
