# $Id$

# D flip-flop.
#
# Six tri-input NAND gates don't translate to ASCII art very well.
# The working version comes from Don Lancaster's _TTL Cookbook_.

package Ttl::FlipFlop::D;
use Moose;
extends 'Stage';
use Ttl::TriNand;
use ObserverTrait;
use EmitterTrait;

has clear => (
	isa     => 'Bool',
	is      => 'rw',
	traits  => ['Emitter'],
);

has clock => (
	isa     => 'Bool',
	is      => 'rw',
	traits  => ['Emitter'],
);

has d => (
	isa     => 'Bool',
	is      => 'rw',
	traits  => ['Emitter'],
);

has preset => (
	isa     => 'Bool',
	is      => 'rw',
	traits  => ['Emitter'],
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

sub BUILD {
	my $self = shift;

	$self->tri1( Ttl::TriNand->new() );
	$self->tri2( Ttl::TriNand->new() );
	$self->tri3( Ttl::TriNand->new() );
	$self->tri4( Ttl::TriNand->new() );
	$self->tri5( Ttl::TriNand->new() );
	$self->tri6( Ttl::TriNand->new() );

	# Toggle clear low/high to clear output.
	$self->preset(1);
	$self->clear(1);
	$self->clock(1);
	$self->d(0);
}

sub on_my_clear {
	my ($self, $args) = @_;
	my $value = $args->{value};
	$self->tri2->b($value);
	$self->tri4->b($value);
	$self->tri6->b($value);
}

sub on_my_clock {
	my ($self, $args) = @_;
	my $value = $args->{value};
	$self->tri2->c($value);
	$self->tri3->b($value);
}

sub on_my_d {
	my ($self, $args) = @_;
	$self->tri4->c($args->{value});
}

sub on_my_preset {
	my ($self, $args) = @_;
	my $value = $args->{value};
	$self->tri1->a($value);
	$self->tri5->a($value);
}

sub on_tri1_out {
	my ($self, $args) = @_;
	$self->tri2->a($args->{value});
}

sub on_tri2_out {
	my ($self, $args) = @_;
	$self->tri1->c($args->{value});
	$self->tri3->a($args->{value});
	$self->tri5->b($args->{value});
}

sub on_tri3_out {
	my ($self, $args) = @_;
	$self->tri4->a($args->{value});
	$self->tri6->c($args->{value});
}

sub on_tri4_out {
	my ($self, $args) = @_;
	$self->tri1->b($args->{value});
	$self->tri3->c($args->{value});
}

sub on_tri5_out {
	my ($self, $args) = @_;
	$self->q($args->{value});
	$self->tri6->a($args->{value});
}

sub on_tri6_out {
	my ($self, $args) = @_;
	$self->not_q($args->{value});
	$self->tri5->c($args->{value});
}


has tri1 => (
  isa     => 'Ttl::TriNand',
  is      => 'rw',
  traits  => ['Observer'],
);

has tri2 => (
  isa     => 'Ttl::TriNand',
  is      => 'rw',
  traits  => ['Observer'],
);

has tri3 => (
  isa     => 'Ttl::TriNand',
  is      => 'rw',
  traits  => ['Observer'],
);

has tri4 => (
  isa     => 'Ttl::TriNand',
  is      => 'rw',
  traits  => ['Observer'],
);

has tri5 => (
  isa     => 'Ttl::TriNand',
  is      => 'rw',
  traits  => ['Observer'],
);

has tri6 => (
  isa     => 'Ttl::TriNand',
  is      => 'rw',
  traits  => ['Observer'],
);

1;
