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
use Reflex::Trait::Observer;

has and => (
  isa     => 'Ttl::And',
  is      => 'rw',
  traits  => ['Reflex::Trait::Observer'],
  handles => [qw(a b)],
	setup   => sub { Ttl::And->new() },
);

has not => (
  isa     => 'Ttl::Not',
  is      => 'rw',
  traits  => ['Reflex::Trait::Observer'],
	setup   => sub { Ttl::Not->new() },
);

sub on_and_out {
  my ($self, $args) = @_;
  $self->not->in($args->{value});
}

sub on_not_out {
  my ($self, $args) = @_;
  $self->out($args->{value});
}

1;
