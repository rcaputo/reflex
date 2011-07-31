#!/usr/bin/perl
# vim: ts=2 sw=2 noexpandtab

use strict;
use warnings;
use feature qw( say );

use Socket qw( AF_INET unpack_sockaddr_in inet_ntoa );
use Socket::GetAddrInfo qw( :newapi getaddrinfo );

sub format_addr {
	my ($port, $inaddr) = unpack_sockaddr_in $_[0];
	sprintf "%s:%d", inet_ntoa($inaddr), $port;
}

use POE qw( Session Kernel Wheel::ReadWrite Wheel::Run Filter::Reference );

{
	my $wheel_resolver;

	POE::Session->create(
		inline_states => {
			_start => sub {
				$wheel_resolver = POE::Wheel::Run->new(
					Program => sub {
						my ($err, @addrs) =
							getaddrinfo("localhost", "www", {family => AF_INET});
						die "$err" if $err;
						print @{POE::Filter::Reference->new->put([$addrs[0]])};
					},
					StdoutFilter => POE::Filter::Reference->new,
					StdoutEvent  => 'resolver_input',
					StderrEvent  => 'resolver_error',
				);
			},

			resolver_input =>
				sub { say "POE resolved " . format_addr($_[ARG0]->{addr}) },
			resolver_error => sub { say "POE resolver error $_[ARG0]" },
		},
	);
}

POE::Kernel->run;

