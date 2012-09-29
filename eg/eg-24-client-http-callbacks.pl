#!/usr/bin/env perl
# vim: ts=2 sw=2 noexpandtab

use warnings;
use strict;
use lib qw(../lib);

# HttpClient is a wrapper for POE::Component::Client::HTTP.
use HttpClient;

### Main usage.

use HTTP::Request;

# 1. Create a user-agent object.

my $ua = HttpClient->new(
	on_response => sub {
		my ($self, $event) = @_;
		print $event->response()->code(), " = ", $event->request->uri(), "\n";
	},
);

# 2. Send a request.

$ua->request( HTTP::Request->new( GET => $_ ) ) foreach (
	'http://poe.perl.org',
	'http://duckduckgo.com/',
	'http://metacpan.org/',
	'http://perl.org/',
	'http://twitter.com/',
);

# 3. Wait for stuff.

Reflex->run_all();

exit;
