package Proxy;
# vim: ts=2 sw=2 noexpandtab

use Moose;
extends 'Reflex::Base';
use Reflex::Callbacks qw(make_null_handler);

has handle_a => ( is => 'rw', isa => 'FileHandle', required => 1 );
has handle_b => ( is => 'rw', isa => 'FileHandle', required => 1 );

has active => ( is => 'ro', isa => 'Bool', default => 1 );

make_null_handler("on_handle_a_closed");
make_null_handler("on_handle_b_closed");
make_null_handler("on_handle_a_error");
make_null_handler("on_handle_b_error");

with 'Reflex::Role::Streaming' => {
	att_active => 'active',
	att_handle => 'handle_a',
};

with 'Reflex::Role::Streaming' => {
	att_active => 'active',
	att_handle => 'handle_b',
};

sub on_handle_a_data {
	my ($self, $arg) = @_;
	$self->put_handle_b($arg->{data});
}

sub on_handle_b_data {
	my ($self, $arg) = @_;
	$self->put_handle_a($arg->{data});
}

1;
