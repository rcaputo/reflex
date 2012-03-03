package ZmqSocket;

use Moose;
extends 'Reflex::Base';

use Errno qw(EAGAIN EINTR);
use ZeroMQ::Raw;
use ZeroMQ::Raw::Constants qw(
	ZMQ_FD ZMQ_NOBLOCK ZMQ_PUB ZMQ_SUB ZMQ_SUBSCRIBE ZMQ_POLLIN
	ZMQ_EVENTS
);

# ZeroMQ message event.  See ZmqMessage.pm in the eg directory.
use ZmqMessage;

# ZeroMQ::Raw::Context

has thread_count => (
	is => 'ro',
	isa => 'Int',
	default => 1,
);

# ZeroMQ::Raw::Socket

has socket_type => (
	is => 'ro',
	isa => 'Int',
	required => 1,
);

# ZeroMQ::Raw::Bind

has endpoints => (
	is => 'ro',
	isa => 'ArrayRef[Str]',
	required => 1,
);

### Misc.

has _zmq_active => ( is => 'rw', isa => 'Bool', default => 1 );

has _zmq_context => (
	is => 'ro',
	isa => 'ZeroMQ::Raw::Context',
	lazy => 1,
	default => sub {
		my $self = shift();
		return ZeroMQ::Raw::Context->new( threads => $self->thread_count() );
	},
);

has _zmq_socket => (
	is => 'ro',
	isa => 'ZeroMQ::Raw::Socket',
	lazy => 1,
	default => sub {
		my $self = shift;

		my $socket = ZeroMQ::Raw::Socket->new(
			$self->_zmq_context(),
			$self->socket_type(),
		);

		# TODO - Some better way to dispatch setup than if() statements.
		#
		# $self->publish( \@endpoints );
		#   Create the socket as ZMQ_PUB.
		#   Bind to the @endpoints.
		#
		# $self->subscribe( \@endpoints );
		#   Create the socket as ZMQ_SUB.
		#   Connect to the @endpoints.

		if ($self->socket_type() == ZMQ_PUB) {
			foreach (@{$self->endpoints()}) {
				$! = 0;
				$socket->bind($_) or warn "can't bind to $_ - $!";
			}
			return $socket;
		}

		if ($self->socket_type() == ZMQ_SUB) {
			foreach (@{$self->endpoints()}) {
				$socket->connect($_);
			}

			$socket->setsockopt(ZMQ_SUBSCRIBE, 'debug:');

			return $socket;
		}

		die "unknown zmq socket type: " . $self->socket_type();
	},
);

has _zmq_filehandle => (
	is => 'ro',
	isa => 'FileHandle',
	lazy => 1,
	default => sub {
		my $self = shift();

		# TODO - Is it necessary to open this socket for append?

		open(
			my $zmq_fh, "+<&=" . $self->_zmq_socket()->getsockopt(ZMQ_FD)
		) or die "filehandle creation failed: $!";

		return $zmq_fh;
	},
);

with 'Reflex::Role::Readable' => {
	att_active    => '_zmq_active',
	att_handle    => '_zmq_filehandle',
	cb_ready      => '_on_zmq_readable',
	method_pause  => 'pause_reading',
	method_resume => 'resume_reading',
	method_stop   => 'stop_reading',
};

sub _on_zmq_readable {
	my ($self, $args) = @_;

	MESSAGE: while (1) {
		return unless $self->_zmq_socket()->getsockopt(ZMQ_EVENTS) & ZMQ_POLLIN;

		my $msg = ZeroMQ::Raw::Message->new();

		unless ($self->_zmq_socket()->recv($msg, ZMQ_NOBLOCK)) {
			$self->emit(
				-name => "message",
				-type => 'ZmqMessage',
				message => $msg,
			);
			next MESSAGE;
		}

		return if $! == EAGAIN or $! == EINTR;

		$self->pause_reading();

		$self->on_error(
			{
				errnum => ($! + 0),
				errstr => "$!",
				errfun => 'zmq_recv',
			}
		);

		return;
	}
}

sub send_scalar {
	my ($self, $scalar) = @_;

	my $message = ZeroMQ::Raw::Message->new_from_scalar($scalar);
	$self->_zmq_socket()->send($message, 0) || 0;
}

1;
