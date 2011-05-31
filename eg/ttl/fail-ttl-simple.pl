#!/usr/bin/perl
# vim: ts=2 sw=2 noexpandtab

use warnings;
use strict;
use lib qw(lib);

{
	package Breadboard;
	use Moose;
	extends 'Reflex::Base';
	use Ttl::And;
	use Reflex::Trait::Watched qw(watches);

	watches ander => ( isa => 'Ttl::And' );

	sub BUILD {
		my $self = shift;
		$self->ander( Ttl::And->new() );
		$self->ander->a(1);
		$self->ander->b(1);
	}

	sub on_ander_out {
		my ($self, $args) = @_;
		warn 111;
		warn "Ander out: $args->{value}\n";
	}
}

Breadboard->new()->run_all();
exit;
