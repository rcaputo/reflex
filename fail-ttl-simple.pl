#!/usr/bin/perl

{
	package Breadboard;
	use Moose;
	extends 'Stage';
	use ObserverTrait;

	use Ttl::And;

	has ander => (
		isa => 'Ttl::And',
		is  => 'rw',
		traits => ['Observer'],
	);

	sub BUILD {
		my $self = shift;
		$self->ander( Ttl::And->new() );
		$self->ander->a(1);
		$self->ander->b(1);
	}

	sub on_ander_out {
		my ($self, $args) = @_;
		warn "Ander out: $args->{value}\n";
	}
}

my $b = Breadboard->new();
Stage->run_all();
exit;
