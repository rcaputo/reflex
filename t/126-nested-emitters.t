# vim: ts=2 sw=2 noexpandtab
use warnings;
use strict;
use Test::More;
use Reflex;

{
	package Contained;
	use Moose;
	extends 'Reflex::Base';

	sub foo {
		my ($self, %args) = @_;
		$self->emit( -name => 'foo_event', %args );
	}
}

{
	package Container;
	use Moose;
	use Reflex::Callbacks('cb_method');
	extends 'Reflex::Base';

	has things => (is => 'ro', isa => 'HashRef', default => sub { {} });

	sub store {
		my ($self, $thing) = @_;
		$self->watch($thing, 'foo_event' => cb_method($self, 'foo_event'));
		$self->things->{$thing} = $thing;
	}

	sub remove {
		my ($self, $thing) = @_;
		$self->ignore($thing);
		delete($self->things->{$thing});
	}

	sub foo_event {
		my ($self, $event) = @_;
		$self->re_emit( $event, -name => 'foo_event' );
		$self->remove($event->get_last_emitter());
	}
}

{
	package Harness;
	use Moose;
	use Reflex::Callbacks('cb_method');
	extends 'Reflex::Base';

	has container => (
		is      => 'ro',
		isa     => 'Container',
		lazy    => 1,
		builder => '_build_container'
	);

	sub _build_container {
		my $self = shift;
		my $cont = Container->new();
		for (0 .. 9) {
			$cont->store(Contained->new());
		}

		$self->watch($cont, 'foo_event' => cb_method($self, 'foo_handler'));

		return $cont;
	}

	my $baz = 0;

	sub foo_handler {
		my ($self, $event) = @_;
		my $source = $event->get_first_emitter();
		Test::More::isa_ok($source, 'Contained', 'got the source of the event');
		my $last = $event->get_last_emitter();
		Test::More::isa_ok(
			$last, 'Container',
			'got the final emitter in the stack'
		);
		my @all = $event->get_all_emitters();
		Test::More::is(scalar(@all), 2, 'got the right number of emitters');

		if ($baz++ == 9) {
			$self->ignore($self->container);
		}
	}
}

my $harness = Harness->new();
foreach my $thing (values %{$harness->container->things}) {
	$thing->foo();
}

$harness->run_all();
done_testing();
