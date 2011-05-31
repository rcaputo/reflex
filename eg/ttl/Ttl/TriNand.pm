# vim: ts=2 sw=2 noexpandtab

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
extends 'Reflex::Base';
use Ttl::TriAnd;
use Ttl::Not;

use Reflex::Trait::EmitsOnChange qw(emits);
use Reflex::Trait::Watched qw(watches);

watches tri_and => ( isa => 'Ttl::TriAnd', handles => [qw(a b c)] );
watches not     => ( isa => 'Ttl::Not'                            );
emits   out     => ( isa => 'Bool'                                );

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
