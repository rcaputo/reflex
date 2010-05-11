package Stream;
use Moose;
extends 'Reflex::Object';

has handle => ( is => 'rw', isa => 'FileHandle', required => 1 );

with 'Streamable' => { handle => 'handle' };

# TODO - Would be nice to alias put_handle() to put().
sub put {
	my $self = shift;
	$self->put_handle(@_);
}

# Default callback emits an event.
# TODO - Common convention.  How to make this generic?
sub on_handle_data {
	my ($self, $args) = @_;
	$self->emit(
		event => "data",
		args => $args
	);
}

# Default callback emits an event.
# TODO - Common convention.  How to make this generic?
sub on_handle_error {
	my ($self, $args) = @_;
	$self->emit(
		event => "data",
		args => $args
	);
}

1;
