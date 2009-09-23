#!/usr/bin/perl

use warnings;
use strict;
use lib qw(lib);

{
	package Breadboard;
	use Moose;
	extends 'Reflex::Object';
	use Reflex::Trait::Observer;

	use Ttl::And;

	has ander => (
		isa => 'Ttl::And',
		is  => 'rw',
		traits => ['Reflex::Trait::Observer'],
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
Reflex::Object->run_all();
exit;
