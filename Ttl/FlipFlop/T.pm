# $Id$

# T flip-flop.  Basically a D flip-flop with _q fed into d.

package Ttl::FlipFlop::T;
use Moose;
extends 'Stage';
use Ttl::FlipFlop::D;
use ObserverTrait;
use EmitterTrait;

has dff => (
	isa     => 'Ttl::FlipFlop::D',
	is      => 'rw',
	traits  => ['Observer'],
	handles => ['preset','clear','clock'],
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

sub on_dff_q {
	my ($self, $args) = @_;
	$self->q($args->{value});
}

sub on_dff_not_q {
	my ($self, $args) = @_;
	$self->not_q($args->{value});
	$self->dff->d($args->{value});
}

sub BUILD {
	my $self = shift;
	$self->dff( Ttl::FlipFlop::D->new() );
	$self->preset(1);
	$self->clear(1);
	$self->clock(0);
}

1;
