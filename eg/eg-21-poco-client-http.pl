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

my $ua = HttpClient->new();

# 2. Send a request.

$ua->request( HTTP::Request->new( GET => 'http://10.0.0.25/' ) );

# 3. Use promise syntax to wait for the next response.

my $event = $ua->next();

# 4. Process the response.

print $event->response()->as_string();

exit;
