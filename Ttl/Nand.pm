# $Id$

# Logical NAND gate.  Built from NOT + AND.
# a b out
# 0 0 1
# 1 0 1
# 0 1 1
# 1 1 0

package Ttl::Nand;
use Moose;
extends 'Ttl::Bin';
use Ttl::Not;
use Ttl::And;
use ObserverTrait;

has and => (
  isa     => 'Ttl::And',
  is      => 'rw',
  traits  => ['Observer'],
  handles => [qw(a b)],
);

has not => (
  isa     => 'Ttl::Not',
  is      => 'rw',
  traits  => ['Observer'],
);

sub BUILD {
  my $self = shift;

  # TODO - I would love to set these from the attributes' "default",
  # but Observer traits won't kick in because Moose doesn't invoke
  # "trigger" on defaults.

  $self->and( Ttl::And->new() );
  $self->not( Ttl::Not->new() );
}

sub on_and_out {
  my ($self, $args) = @_;
  $self->not->in($args->{value});
}

sub on_not_out {
  my ($self, $args) = @_;
  $self->out($args->{value});
}

1;
