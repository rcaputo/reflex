package Reflex::Codec::Message;

use Moose;

has is_combinable => ( is => 'ro', isa => 'Bool', default => 0 );

# TODO - Currently unused, but eventually "push" will honor priority.

has priority => (
	is      => 'rw',
	isa     => 'Int',
	default => 500,
);

1;
