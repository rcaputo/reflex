package AfterAwhileClass;
use Moose;
extends 'Reflex::Base';

has name    => ( is => 'ro', isa => 'Str', default => 'awhile' );
has awhile  => ( is => 'ro', isa => 'Int', default => 1 );

with 'AfterAwhileRole' => {
	cb => make_emitter(on_done => "done"),
};

1;
