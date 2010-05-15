package Stream;
use Moose;
extends 'Reflex::Object';

has handle => ( is => 'rw', isa => 'FileHandle', required => 1 );

with 'Streamable' => {
	handle => 'handle',

	# Expose put_handle() as put().
	-alias => { put_handle => 'put' },
	-excludes => 'put_handle',
};

1;
