package Reflex::Event::Error;

use Moose;
extends 'Reflex::Event';

has number => (
	is       => 'ro',
	isa      => 'Int',
	required => 1,
);

has string => (
	is       => 'ro',
	isa      => 'Str',
	required => 1,
);

has function => (
	is       => 'ro',
	isa      => 'Str',
	required => 1,
);

has formatted => (
	is      => 'ro',
	isa     => 'Str',
	lazy    => 1,
	default => sub {
		my $self = shift();
		return(
			$self->function() . " error " . $self->number() . ": " .  $self->string()
		);
	}
);

1;
