package Reflex::Callback;

use Moose;
use Reflex::Object;

# It's a class if it's a Str.
has object => (
	is        => 'ro',
	isa       => 'Object|Str',  # TODO - Reflex::Object|Str
	weak_ref  => 1,
);

1;
