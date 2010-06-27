#!/usr/bin/perl

use warnings;
use strict;
use lib qw(lib);

{
	package Breadboard;
	use Moose;
	extends 'Reflex::Base';
	use Reflex::Trait::Observed;

	use Ttl::And;

	has ander => (
		isa => 'Ttl::And',
		is  => 'rw',
		traits => ['Reflex::Trait::Observed'],
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
Reflex->run_all();
exit;
