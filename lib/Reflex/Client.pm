# A simple socket client.  Generic enough to be used for INET and UNIX
# sockets, although we may need to specialize for each kind later.

# TODO - This is a simple strawman implementation.  It will need
# refinement.

package Reflex::Client;
use Moose;
use Reflex::Stream;
use Reflex::Connector;
extends 'Reflex::Connector';

has protocol => (
	is      => 'rw',
	isa     => 'Str',
	default => 'Reflex::Stream',
);

has connection => (
	is      => 'rw',
	isa     => 'Maybe[Reflex::Stream]',
	traits  => ['Reflex::Trait::Observer'],
);

sub on_connector_connected {
	my ($self, $args) = @_;

	$self->stop();

	$self->connection(
		$self->protocol()->new(
			handle => $args->{socket},
			rd     => 1,
		)
	);
}

sub on_connector_fail {
	my ($self, $args) = @_;
	warn "$args->{errfun} error $args->{errnum}: $args->{errstr}\n";
	$self->stop();
}

sub on_connection_close {
	my ($self, $args) = @_;
	warn "server closed connection.\n";
	$self->stop();
}

sub on_connection_fail {
	my ($self, $args) = @_;
	warn "$args->{errfun} error $args->{errnum}: $args->{errstr}\n";
	$self->stop();
}

after stop => sub {
	my $self = shift;
	$self->connection(undef);
};

1;
