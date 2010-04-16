package EchoStream;
use Moose;
extends 'Reflex::Stream';

sub on_stream_data {
	my ($self, $args) = @_;
	$self->put($args->{data});
}

sub on_stream_failure {
	my ($self, $args) = @_;
	warn "$args->{errfun} error $args->{errnum}: $args->{errstr}\n";
	$self->emit( event => "shutdown", args => {} );
}

sub on_stream_closed {
	my ($self, $args) = @_;
	$self->emit( event => "shutdown", args => {} );
}

sub DEMOLISH {
	print "EchoStream demolished as it should.\n";
}

1;
