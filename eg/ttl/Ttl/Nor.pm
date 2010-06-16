# $Id$

# Logical NOR gate.  Built from NOT + OR.
# a b out
# 0 0 1
# 1 0 0
# 0 1 0
# 1 1 0

package Ttl::Nor;
use Moose;
extends 'Ttl::Bin';
use Ttl::Not;
use Ttl::Or;
use Reflex::Trait::Observed;

# Ttl::Or handles a and b input for Ttl::Nor.
has or => (
  isa     => 'Ttl::Or',
  is      => 'rw',
  traits  => ['Reflex::Trait::Observed'],
  handles => [qw(a b)],
);

has not => (
  isa     => 'Ttl::Not',
  is      => 'rw',
  traits  => ['Reflex::Trait::Observed'],
);

sub BUILD {
  my $self = shift;

  $self->or( Ttl::Or->new() );
  $self->not( Ttl::Not->new() );
}

sub on_or_out {
  my ($self, $args) = @_;
  $self->not->in($args->{value});
}

sub on_not_out {
  my ($self, $args) = @_;
  $self->out($args->{value});
}

1;
