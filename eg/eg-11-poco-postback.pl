#!/usr/bin/env perl

use warnings;
use strict;
use lib qw(../lib);

# Exercise Reflex::POE::Postback, for passing postbacks into POE space.

{
	package App;

	use Moose;
	extends 'Reflex::Base';
	use Reflex::POE::Postback;
	use PoCoPostback;

	has component => (
		isa => 'Object|Undef',
		is  => 'rw',
	);

	sub BUILD {
		my $self = shift;

		# PoCoPostbck is used as an object.
		$self->component( PoCoPostback->new() );

		# Send the component a Reflex::POE::Postback, which looks and
		# feels like a POE::Session postback but invokes Reflex callbacks.
		#
		# The request() call here could be replaced with
		# $poe_kernel->post(...) assuming you import $poe_kernel and
		# understand how to address the component.  PoCoPostback provides
		# the request() method to gloss over these details.
		$self->component->request(
			Reflex::POE::Postback->new(
				$self, "on_component_result", { cookie => 123 }
			),
		);
	}

	sub on_component_result {
		my ($self, $args) = @_;
		print(
			"Got component response:\n",
			"  postback context: $args->{context}{cookie}\n",
			"  call-back result: $args->{response}[0]\n",
		);

		# Ok, we're done.
		$self->component(undef);
	}
}

# Main.

my $app = App->new();
$app->run_all();
exit;
