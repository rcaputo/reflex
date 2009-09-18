#!/usr/bin/env perl

# Exercise the PoeEvent class, for passing events into POE space.

{
	package App;

	use Moose;
	extends 'Stage';
	use PoeEvent;
	use PoCoEvent;

	has component => (
		isa => 'Object|Undef',
		is  => 'rw',
	);

	sub BUILD {
		my $self = shift;
		$self->component( PoCoEvent->new() );

		$self->run_within_session(
			sub {
				$self->component->request(
					PoeEvent->new(
						stage   => $self,
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
			"  pass-through cookie: $args->{passthrough}{cookie}\n",
			"  call-back result   : $args->{callback}[1][0]\n",
		);

		# Ok, we're done.
		$self->component(undef);
	}
}

my $app = App->new();
$app->run_all();
exit;
