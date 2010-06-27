#!/usr/bin/env perl

use warnings;
use strict;
use lib qw(../lib);

# Exercise Reflex::POE::Event, for passing events into POE space.

{
	package App;

	use Moose;
	extends 'Reflex::Base';
	use Reflex::POE::Event;
	use PoCoEvent;

	has component => (
		isa => 'Object|Undef',
		is  => 'rw',
	);

	sub BUILD {
		my $self = shift;
		$self->component( PoCoEvent->new() );

		# TODO - Make this more convenient.
		$self->run_within_session(
			sub {
				$self->component->request(
					Reflex::POE::Event->new(
						object  => $self,
						method  => "on_component_result",
						context => { cookie => 123 },
					),
				);
			}
		);
	}

	sub on_component_result {
		my ($self, $args) = @_;
		print(
			"Got component response:\n",
			"  event context    : $args->{context}{cookie}\n",
			"  call-back result : $args->{response}[1][0]\n",
		);

		# Ok, we're done.
		$self->component(undef);
	}
}

# Main.

my $app = App->new();
$app->run_all();
exit;
