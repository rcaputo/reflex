package HttpClient;

use Moose;
extends 'Reflex::Base';

use POE::Component::Client::HTTP;
use Reflex::POE::Event;
use HttpResponseEvent;

has alias => (
	is      => 'ro',
	isa     => 'Str',
	default => 'user-agent',
);

sub BUILD {
	my ($self) = @_;

	# Start an HTTP user-agent when the object is created.
	#
	# A more complete example would expose all of PoCo::Client::HTTP's
	# configuration options as attributes.

	POE::Component::Client::HTTP->spawn(Alias => $self->alias());
}

sub DESTRUCT {
	my ($self) = @_;

	# Shut down POE::Component::Client::HTTP when this object is
	# destroyed.

	POE::Kernel->post(ua => $self->alias());
}

sub request {
	# Make a request.

	my ($self, $http_request) = @_;

	# There is no guarantee that the caller of request() is running in
	# the same POE session as this HttpClient object.
	#
	# Reflex::Base's run_within_session() method makes sure that the
	# right session is active when interacting with POE code.  This
	# ensures that POE-based responses are properly routed.

	# The Reflex::POE::Event object created here is an event for POE's
	# purpose, but it includes Reflex magic to route responses back to
	# the correct Reflex object.

	$self->run_within_session(
		sub {
			POE::Kernel->post(
				$self->alias(),
				'request',
				Reflex::POE::Event->new(
					object => $self,
					method => 'internal_http_response',
				),
				$http_request,
			);
		}
	);
}

sub internal_http_response {
	my ($self, $args) = @_;

	my ($request, $response) = @{ $args->{response} };
	$self->emit(
		-type    => 'HttpResponseEvent',
		-name    => 'response',
		request  => $request->[0],
		response => $response->[0],
	);
}

1;
