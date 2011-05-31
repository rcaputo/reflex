#!/usr/bin/env perl
# vim: ts=2 sw=2 noexpandtab

use lib qw(../lib);

{
	package Echoer;
	use Moose;
	extends 'Reflex::Base';

	sub ping {
		my ($self, $args) = @_;
		print "Echoer was pinged!\n";
		$self->emit( event => "pong" );
	}
}

{
	package Pinger;
	use Moose;
	extends 'Reflex::Base';
	use Reflex::Trait::Watched qw(watches);

	watches echoer => (
		isa     => 'Echoer',
		default => sub { Echoer->new() },
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
