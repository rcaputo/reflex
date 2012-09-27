#!/usr/bin/env perl
# vim: ts=2 sw=2 noexpandtab

use warnings;
use strict;
use lib qw(../lib);

{
	package ConcurrentHttpClient;
	use Moose;
	extends 'Reflex::Base';

	use HttpClient;
	use Reflex::Trait::Watched qw(watches);

	watches http_client => (
		is      => 'ro',
		isa     => 'HttpClient',
		default => sub { HttpClient->new() },
	);

	has pending => (
		is      => 'rw',
		isa     => 'Int',
		default => 0,
	);

	sub requests {
		my ($self, @http_requests) = @_;

		foreach my $request (@http_requests) {
			$self->http_client()->request( $request );
		}

		$self->pending( $self->pending() + @http_requests );
	}

	sub on_http_client_response {
		my ($self, $response) = @_;
		$self->re_emit( $response, -name => 'response' );

		return if $self->pending( $self->pending() - 1 );

		$self->emit( -name => "empty" );
	};
}

### Main usage.

use HTTP::Request;

my $client = ConcurrentHttpClient->new();
$client->requests(
	map { HTTP::Request->new( GET => $_ ) }
	'http://poe.perl.org',
	'http://duckduckgo.com/',
	'http://metacpan.org/',
	'http://perl.org/',
	'http://twitter.com/',
);

while (my $event = $client->next()) {
	last if $event->_name() eq 'empty';
	print $event->response()->code(), " = ", $event->request()->uri(), "\n";
}

exit;
