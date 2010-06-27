package EchoStream;
use Moose;
extends 'Reflex::Stream';

sub on_handle_data {
	my ($self, $args) = @_;
	$self->put($args->{data});
}

sub on_handle_error {
	my ($self, $args) = @_;
	warn "$args->{errfun} error $args->{errnum}: $args->{errstr}\n";
	$self->emit( event => "stopped", args => {} );
}

sub on_handle_closed {
	my ($self, $args) = @_;
	$self->emit( event => "stopped", args => {} );
}

sub DEMOLISH {
	print "EchoStream demolished as it should.\n";
}

1;
