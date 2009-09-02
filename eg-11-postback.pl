#!/usr/bin/env perl

# Exercise the Postback class, for passing postbacks into POE space.

{
	package App;

	use Moose;
	extends 'Stage';
	use Postback;
	use PoCoPostback;

	has component => (
		isa => 'Object|Undef',
		is  => 'rw',
	);

	sub BUILD {
		my $self = shift;
		$self->component( PoCoPostback->new() );

		$self->component->request(
			Postback->new($self, "on_component_result", { cookie => 123 }),
		);
	}

	sub on_component_result {
		my ($self, $args) = @_;
		print(
			"Got component response:\n",
			"  pass-through cookie: $args->{passthrough}{cookie}\n",
			"  call-back result   : $args->{callback}[0]\n",
		);

		# Ok, we're done.
		$self->component(undef);
	}
}

my $app = App->new();
$app->run_all();
exit;
