# $Id$

# Three-input logical NAND gate.  Built from TriAnd + Not.
# a b c out
# 0 0 0 1
# 1 0 0 1
# 0 1 0 1
# 1 1 0 1
# 0 0 1 1
# 1 0 1 1
# 0 1 1 1
# 1 1 1 0
#
# a --\
# b ---(TriAnd)--(Not)-- out
# c --/

package Ttl::TriNand;
use Moose;
extends 'Stage';
use Ttl::TriAnd;
use Ttl::Not;
use ObserverTrait;
use EmitterTrait;

has tri_and => (
	isa     => 'Ttl::TriAnd',
	is      => 'rw',
	traits  => ['Observer'],
	handles => [qw(a b c)],
);

has not => (
  isa     => 'Ttl::Not',
  is      => 'rw',
  traits  => ['Observer'],
);

has out => (
	isa     => 'Bool',
	is      => 'rw',
	traits  => ['Emitter'],
);

sub BUILD {
	my $self = shift;

  $self->tri_and( Ttl::TriAnd->new() );
  $self->not( Ttl::Not->new() );
}

sub on_tri_and_out {
  my ($self, $args) = @_;
  $self->not->in($args->{value});
}

sub on_not_out {
  my ($self, $args) = @_;
  $self->out($args->{value});
}

1;
