#!/usr/bin/env perl
# vim: ts=2 sw=2 noexpandtab

use warnings;
use strict;
use lib qw(../lib);

my $rot13_server_port = 12345;

### Bot::BasicBot bot.  Bot bot bot bot bot!
#
# Create a classing Bot::BasicBot, but use Reflex::Client within it to
# talk to a server asynchronously.

{
	package MyBot;
	use Moose;
	use MooseX::NonMoose;
	extends 'Bot::BasicBot', 'Reflex::Base';
	use Reflex::Collection;
	use Reflex::Client;

	has_many clients => ( handles => { remember_client => "remember" } );

	sub said {
		my ($mybot, $bot_event) = @_;

		my $said = $bot_event->{body};
		return unless $said =~ /^\s*rot13\s*(\S.*?)\s*$/;
		my $to_rot_13 = $1;

		$mybot->remember_client(
			Reflex::Client->new(
				port => $rot13_server_port,
				on_connected => sub {
					my $client = shift;
					$client->put($to_rot_13);
				},
				on_data => sub {
					my ($client, $response) = @_;
					$mybot->say(
						channel => $bot_event->{channel},
						body    => $response->{data},
					);
					$client->stop();
				},
			),
		);

		# Say nothing now.
		return;
	}
}

### Reflex rot13 server.
#
# We're embedding a small server within the bot for testing.
# The idea of a rot13 server is pretty silly, but it serves (har) as a
# good, small example.
#
# It also illustrates that isolated Reflexy things still work.

{
	# A stream that echoes back whatever it receives after rot13
	# encrypting it.

	{
		package Rot13EchoStream;
		use Moose;
		extends 'Reflex::Stream';

		sub on_data {
			my ($self, $args) = @_;
			my $text = $args->{data};
			warn "Server has been asked to rot13('$text')...\n";
			$text =~ tr[a-zA-Z][n-za-mN-ZA-M];
			$self->put($text);
		}
	}

	# The rot13 server itself.
	# It's your basic Reflex server using Rot13EchoStream to handle
	# client connections.

	{
		package Rot13Server;

		use Moose;
		extends 'Reflex::Acceptor';
		use Reflex::Collection;

		has_many clients => ( handles => { remember_client => "remember" } );

		sub on_accept {
			my ($self, $args) = @_;
			$self->remember_client(
				Rot13EchoStream->new( handle => $args->{socket} )
			);
		}

		sub on_error {
			my ($self, $args) = @_;
			warn "$args->{errfun} error $args->{errnum}: $args->{errstr}\n";
			$self->stop();
		}
	}
}

### Main program.
#
# Start the rot13 server so it's there for the bot.
# Start the bot.
# Run it all, forever, via the bot's main loop.

my $server = Rot13Server->new(
	listener => IO::Socket::INET->new(
		LocalAddr => '127.0.0.1',
		LocalPort => $rot13_server_port,
		Listen    => 5,
		Reuse     => 1,
	),
);

my $bot = MyBot->new(
	server    => "irc.perl.org",
	channels  => ["#bots"],

	nick      => "reflex-eg-42",
	username  => "bot",
	name      => "Reflex Example 42 Bot",

	charset => "utf-8",
)->run();

__END__

Inspiration:

17:18      kthakore : awnstudio_: yeah me
17:18      kthakore : dngor: right ..
17:18      kthakore : but how do I plug it into Bot::BasicBot
17:19         dngor : When you get the trigger from Bot::BasicBot, open a
                      socket, send a request, and wait for a response.
17:19         dngor : You could use IO::Socket::INET and
											$poe_kernel->select_read(), or something higher level.
17:19      kthakore : http://github.com/PerlGameDev/SDL/blob/master/tools/SDLBot.pl
17:20      kthakore : but where do I get $poe_kernel from?
17:20         dngor : If the server is localhost, the connect() will tend to
											pass or fail pretty quickly... unless your firewall is
											interfering with localhost.  So blocking is generally not
                      a problem.
17:20      kthakore : I mean I know BasicBot uses Poe
17:20         dngor : Presumably Bot::BasicBot passes it to you, in the
                      standard POE way.  If not, POE::Kernel exports it.
17:21         dngor : Hm.  There's an excellent exercise.  Using Reflex INSIDE
                      POE components.
17:21         dngor : Bot::BasicBot + Reflex::Client
17:22      kthakore : dngor: whut is reflex ... and how do I use it?
17:23         dngor : It's neither here nor there.  I'm just brainstorming aloud.
17:23      kthakore : dngor: oh ok
