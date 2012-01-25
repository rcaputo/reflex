#!/usr/bin/env perl
# vim: ts=2 sw=2 noexpandtab

use warnings;
use strict;
use lib qw(../lib);

# Exercise Reflex::POE::Event, for passing events into POE space.

# For a more practical application, see eg-21-poco-client-http.pl.
# That example wraps POE::Component::Client::HTTP in a similar way.

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

		# TODO - Make the following more convenient.

		# BUILD may be called synchronously from any old POE session.
		# Switch to the session associated with the object being built.
		# This allows the component to receive the proper $_[SENDER],
		# which it will then use to respond back to this Reflex object.
		$self->run_within_session(
			sub {
				# The request() call here could be replaced with
				# $poe_kernel->post(...) assuming you import $poe_kernel and
				# understand how to address the component.  PoCoEvent provides
				# the request() method to gloss over these details.
				$self->component->request(
					# Reflex::POE::Event looks and feels like a POE event, but
					# it includes magic to route responses back to the correct
					# Reflex object.
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
