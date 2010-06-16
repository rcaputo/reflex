#!/usr/bin/env perl

use lib qw(../lib);

{
	package Echoer;
	use Moose;
	extends 'Reflex::Object';

	sub ping {
		my ($self, $args) = @_;
		print "Echoer was pinged!\n";
		$self->emit( event => "pong" );
	}
}

{
	package Pinger;
	use Moose;
	extends 'Reflex::Object';

	has echoer => (
		is      => 'ro',
		isa     => 'Echoer',
		default => sub { Echoer->new() },
		traits  => ['Reflex::Trait::Observed'],
	);

	sub BUILD {
		my $self = shift;
		$self->echoer->ping();
	}

	sub on_echoer_pong {
		my $self = shift;
		print "Pinger got echoer's pong!\n";
		$self->echoer->ping();
	}
}

Pinger->new()->run_all();
