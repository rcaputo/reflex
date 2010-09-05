#!/usr/bin/env perl

use warnings;
use strict;

die "This is a stub of an example.  See the source for notes to make it real.\n";

__END__

It should be possible to use Reflex within POE programs without ill effects.

TODO:

	Install Bot::BasicBot.
	Create a Bot::BasicBot version of eg-13-irc-bot.pl
	Embed a Reflex::Server within the bot.
		The server should take significant time to respond.
		This will allow requests to back up, testing re-entrancy.
	Use Reflex::Client within the bot to talk to a server.
	Test re-entrancy.
		Two or more requests should back up in the server.
		The bot, the server, and the client should all keep working.

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
