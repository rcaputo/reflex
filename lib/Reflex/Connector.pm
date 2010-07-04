package Reflex::Connector;

use Moose;
extends 'Reflex::Base';

has socket => (
	is        => 'rw',
	isa       => 'FileHandle',
);

has port => (
	is => 'ro',
	isa => 'Int',
);

has address => (
	is      => 'ro',
	isa     => 'Str',
	default => '127.0.0.1',
);

with 'Reflex::Role::Connecting' => {
	connector   => 'socket',      # Default!
	address     => 'address',     # Default!
	port        => 'port',        # Default!
	cb_success  => 'on_connection',
	cb_error    => 'on_error',
};

1;

__END__

TODO - Document.
