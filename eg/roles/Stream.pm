package Stream;
use Moose;
extends 'Reflex::Object';

has handle => ( is => 'rw', isa => 'FileHandle', required => 1 );

with 'Streamable' => { handle => 'handle' };

sub put {
	my $self = shift;
	$self->put_handle(@_);
}

sub on_handle_data {
	my ($self, $args) = @_;
	warn $args->{data};
	$self->emit(
		event => "data",
		args => $args
	);
}

1;
