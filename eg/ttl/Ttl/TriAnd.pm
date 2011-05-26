# $Id$

# Three-input logical AND gate.  Built from a couple ANDs.
# a b c out
# 0 0 0 0
# 1 0 0 0
# 0 1 0 0
# 1 1 0 0
# 0 0 1 0
# 1 0 1 0
# 0 1 1 0
# 1 1 1 1
#
# a --\
#      (AND ab)--\
# b --/           (AND c)-- out
# c--------------/

package Ttl::TriAnd;
use Moose;
extends 'Reflex::Base';
use Ttl::And;

use Reflex::Trait::Watched;
use Reflex::Trait::EmitsOnChange;

watches and_ab => ( isa => 'Ttl::And', handles => [qw(a b)]    );
watches and_c  => ( isa => 'Ttl::And', handles => { c => 'b' } );
emits   out    => ( isa => 'Bool'                              );

sub BUILD {
	my $self = shift;
  $self->and_ab( Ttl::And->new() );
  $self->and_c( Ttl::And->new() );
}

sub on_and_ab_out {
  my ($self, $args) = @_;
  $self->and_c->a($args->{value});
}

sub on_and_c_out {
  my ($self, $args) = @_;
	warn $args->{value};
  $self->out($args->{value});
}

1;
