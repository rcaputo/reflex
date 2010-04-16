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
	# Maps $self->put() to $self->connection()->put().
	# TODO - Would be nice to have something like this for outbout
	# events.  See on_connection_data() later in this module for more.
	handles => ['put'],
);

sub on_connector_success {
	my ($self, $args) = @_;

	$self->stop();

	$self->connection(
		$self->protocol()->new(
			handle => $args->{socket},
			rd     => 1,
		)
	);

	$self->emit(event => "connected", args => {});
}

sub on_connector_failure {
	my ($self, $args) = @_;
	warn "$args->{errfun} error $args->{errnum}: $args->{errstr}\n";
	$self->stop();
}

sub on_connection_closed {
	my ($self, $args) = @_;
	warn "server closed connection.\n";
	$self->stop();
}

sub on_connection_failure {
	my ($self, $args) = @_;
	warn "$args->{errfun} error $args->{errnum}: $args->{errstr}\n";
	$self->stop();
}

# This odd construct lets us rethrow a low-level event as a
# higher-level event.  It's similar to the way Moose "handles" works,
# although in the other (outbound) direction.
# TODO - It's rather inefficient to rethrow like this at runtime.
# Some compile- or init-time remapping construct would be better.
sub on_connection_data {
	my ($self, $args) = @_;
	$self->emit( event => "data", args => $args );
}

after stop => sub {
	my $self = shift;
	$self->connection(undef);
};

1;
