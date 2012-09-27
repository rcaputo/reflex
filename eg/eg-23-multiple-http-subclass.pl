#!/usr/bin/env perl
# vim: ts=2 sw=2 noexpandtab

use warnings;
use strict;
use lib qw(../lib);

{
	package ConcurrentHttpClient;
	use Moose;
	extends 'HttpClient';

	has pending => (
		is      => 'rw',
		isa     => 'Int',
		default => 0,
	);

	after request => sub {
		my ($self) = @_;
		$self->pending( $self->pending() + 1 );
	};

	after internal_http_response => sub {
		my ($self) = @_;
		return if $self->pending( $self->pending() - 1 );
		$self->emit( -name => "empty" );
	};
}

### Main usage.

use HTTP::Request;

my $client = ConcurrentHttpClient->new();
$client->request( HTTP::Request->new( GET => $_ ) ) foreach (
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
