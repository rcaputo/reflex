package Proxy;
use Moose;
extends 'Reflex::Object';

has handle_a => ( is => 'rw', isa => 'FileHandle', required => 1 );
has handle_b => ( is => 'rw', isa => 'FileHandle', required => 1 );

with 'Reflex::Role::Streaming' => { handle => 'handle_a' };
with 'Reflex::Role::Streaming' => { handle => 'handle_b' };

sub on_handle_a_data {
	my ($self, $arg) = @_;
	$self->put_handle_b($arg->{data});
}

sub on_handle_b_data {
	my ($self, $arg) = @_;
	$self->put_handle_a($arg->{data});
}

1;
