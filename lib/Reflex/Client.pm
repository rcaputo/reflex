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

has server => (
	is      => 'rw',
	isa     => 'Maybe[Reflex::Stream]',
	traits  => ['Reflex::Trait::Observer'],
);

sub on_my_connected {
	my ($self, $args) = @_;

	# TODO - Reflex::Handle should make this convenient.
	$self->stop();
	$self->handle(undef);

	$self->server(
		$self->protocol()->new(
			handle => $args->{socket},
			rd     => 1,
		)
	);
}

sub on_my_fail {
	my ($self, $args) = @_;
	warn "$args->{errfun} error $args->{errnum}: $args->{errstr}\n";

	# TODO - Reflex::Handle should make this convenient.
	$self->stop();
	$self->handle(undef);
}

sub on_server_close {
	my ($self, $args) = @_;
	warn "server closed connection.\n";

	# TODO - Reflex::Handle should make this convenient.
	$self->sever()->stop();
	$self->server(undef);
}

sub on_server_fail {
	my ($self, $args) = @_;
	warn "$args->{errfun} error $args->{errnum}: $args->{errstr}\n";

	# TODO - Reflex::Handle should make this convenient.
	$self->server()->stop();
	$self->server(undef);
}

1;
