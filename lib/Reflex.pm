package Reflex;

use warnings;
use strict;

use Carp qw(croak);

sub import {
	my $class = shift;
	my $caller_package = caller();

	# Use the packages in the caller's package.
	# TODO - Is there a way to place the use in the caller's package
	# without the eval?

	eval join(
		"; ",
		"package $caller_package",
		map { "use $class\::$_" }
		@_
	);

	# Rewrite the error so that it comes from the caller.
	if ($@) {
		my $msg = $@;
		$msg =~ s/(\(\@INC contains.*?\)) at .*/$1/s;
		croak $msg;
	}
}

sub run_all {
	Reflex::Object->run_all();
}

1;

__END__

=head1 NAME

Reflex - Class library for flexible, reactive programs.

=head1 SYNOPSIS

	# See eg-18-synopsis-no-moose.pl if you don't like Moose.
	# See eg-32-promise-tiny.pl if you prefer condvars.
	# See eg-36-coderefs-tiny.pl if you prefer coderefs and/or closures.

	{
		package App;
		use Moose;
		extends 'Reflex::Object';
		use Reflex::Timer;

		has ticker => (
			isa     => 'Reflex::Timer',
			is      => 'rw',
			setup   => { interval => 1, auto_repeat => 1 },
			traits  => [ 'Reflex::Trait::Observer' ],
		);

		sub on_ticker_tick {
			print "tick at ", scalar(localtime), "...\n";
		}
	}

	exit App->new()->run_all();

=head1 DESCRIPTION

Reflex is a library of classes that assist with writing reactive (AKA
event-driven) programs.  Reflex uses Moose internally, but it doesn't
enforce programs to use Moose's syntax.  However, Moose syntax brings
several useful features we hope will become indispensible.

Reflex is considered "reactive" because it's an implementation of the
reactor pattern.  http://en.wikipedia.org/wiki/Reactor_pattern

=head2 About Reactive Objects

Reactive objects provide responses to interesting (to them) stimuli.
For example, an object might be waiting for input from a client, a
signal from an administrator, a particular time of day, and so on.
The App object in the SYNOPSIS is waiting for timer ticks.  It
generates console messages in response to those timer ticks.

=head2 Example Reactive Objects

Here an Echoer class emits "pong" events in response to ping()
commands.  It uses Moose's extends(), but it could about as easily use
warnings, strict, and base instead.  Reflex::Object provides emit().

	package Echoer;
	use Moose;
	extends 'Reflex::Object';

	sub ping {
		my ($self, $args) = @_;
		print "Echoer was pinged!\n";
		$self->emit( event => "pong" );
	}

The next object uses Echoer.  It creates an Echoer and pings it to get
started. It also reacts to "pong" events by pinging the Echoer again.
Reflex::Trait::Observer implicitly observes the object in echoer(),
mapping its "pong" event to the on_echoer_pong() method.

	package Pinger;
	use Moose;
	extends 'Reflex::Object';

	has echoer => (
		is      => 'ro',
		isa     => 'Echoer',
		default => sub { Echoer->new() },
		traits  => ['Reflex::Trait::Observer'],
	);

	sub BUILD {
		my $self = shift;
		$self->echoer->ping();
	}

	sub on_echoer_pong {
		my $self = shift;
		print "Pinger got echoer's pong!\n";
		$self->echoer->ping();
	}

Then the Pinger would be created and run.

	Pinger->new()->run_all();

A complete, runnable version of this example is in the distribution as
eg/eg-37-ping-pong.pl.

=head2 Coderef Callbacks

Reflex supports any conceivable callback type, even the simple ones:
plain old coderefs.  In other words, you don't need to write objects
to handle events.

Here we'll start a periodic timer and handle its ticks with a simple
callback.  The program is still reactive.  Every second it prints
"timer ticked" in response Reflex::Timer's events.

	use Reflex::Timer;
	use ExampleHelpers qw(eg_say);
	use Reflex::Callbacks qw(cb_coderef);

	my $t = Reflex::Timer->new(
		interval    => 1,
		auto_repeat => 1,
		on_tick     => cb_coderef { eg_say("timer ticked") },
	);

	$t->run_all();

cb_coderef() is explicit placeholder syntax until a final syntax is
decided upon.

A complete, runnable version of the above example is available as
eg/eg-36-tiny-coderefs.pl in the distribution.

=head2 Condvars Instead of Callbacks

Callback haters are not left out.  Reflex objects may also be used as
condvars.  The following example is identical in function to the
previous coderef callback example, but it doesn't use callbacks at
all.

It may not be obvious, but the same emit() method drives all of
Reflex's forms of callback.  Reflex::Timer below is identical to the
Reflex::Timer used differently elsewhere.

	use Reflex::Timer;
	use ExampleHelpers qw(eg_say);

	my $t = Reflex::Timer->new(
		interval => 1,
		auto_repeat => 1,
	);

	while (my $event = $t->wait()) {
		eg_say("wait() returned an event (@$event)");
	}

=head1 BUNDLED CLASSES AND DOCUMENTATION INDEX

Reflex bundles a number of helpful base classes to get things started.

  Reflex::Role::Object - Reflex object role
  | Reflex::Object - Base class for Reflex objects
  | | Reflex::Handle - filehandle watcher
  | | | Reflex::Connector - client socket connector
  | | | | Reflex::Client - socket client with buffered I/O
  | | | Reflex::Listener - server socket listener/acceptor
  | | | Reflex::Stream - asynchronous I/O stream
  | | Reflex::Signal - signal watcher
  | | | Reflex::PID - SIGCHLD watcher
  | | Reflex::Timer - time watcher
  | | Reflex::POE::Session - POE::Session watcher
  | | Reflex::POE::Wheel - POE::Wheel watcher
  | | | Reflex::POE::Wheel::Run - POE::Wheel::Run wrapped in Reflex
  | | Reflex::Collection - automates object destruction
  | Reflex::Role::UdpPeer - UDP socket receiver/sender role
  |   Reflex::UdpPeer - UDP sockets base class
  Reflex::Callbacks - helpful callback functions
  Reflex::Callback - base class for Reflex callbacks
  | Reflex::Callback::CodeRef - simple coderef callback adapter
  | Reflex::Callback::Method - adapts callbacks to methods
  | Reflex::Callback::Promise - adapts callbacks to condvars
  Reflex::POE::Event - represents POE events in Reflex
  Reflex::POE::Postback - represents POE postbacks in Reflex
  Reflex::Trait::Emitter - emit events when a member's value changes
  Reflex::Trait::Observer - observe events emitted by a member object
  Reflex - helper functions and documentation

=head1 ASSISTANCE

See irc.perl.org #reflex for help with Reflex.

See irc.perl.org #moose for help with Moose.

See irc.perl.org #poe for help with POE and Reflex.

Support is officially available from POE's mailing list as well.  Send
a blank message to
L<poe-subscribe@perl.org|mailto:poe-subscribe@perl.org>
to join.

The Reflex package also has helpful examples which may serve as a
tutorial until Reflex is documented more.

=head1 ACKNOWLEDGEMENTS

irc.perl.org channel
L<#moose|irc://irc.perl.org/moose>
and
L<#poe|irc://irc.perl.org/poe>.
The former for assisting in learning their fine libraries, sometimes
against everyone's better judgement.  The latter for putting up with
lengthy and sometimes irrelevant design discussion for oh so long.

=head1 SEE ALSO

L<Moose>, L<POE>, the Reflex namespace on CPAN.

TODO - Set up ohlo.

TODO - Set up CIA.

TODO - Set up home page.

=head1 BUGS

We appreciate your feedback, bug reports, feature requests, patches
and kudos.  You may enter them into our request tracker by following
the instructions at
L<https://rt.cpan.org/Dist/Display.html?&Queue=Reflex>.

We also accept e-mail at
L<bug-Reflex@rt.cpan.org|mailto:bug-Reflex@rt.cpan.org>.

=head1 AUTHORS

Rocco Caputo, RCAPUTO on CPAN.

=head2 CONTRIBUTORS

Reflex is open source, and we welcome involvement.

Chris Fedde, CFEDDE on CPAN

=over 2

=item * L<https://github.com/rcaputo/reflex>

=item * L<http://gitorious.org/reflex>

=back

=head1 TODO

Please browse the source for the TODO marker.  Some are visible in the
documentation, and others are sprinlked around in the code's comments.

Also see L<docs/requirements.otl> in the distribution.  This is a Vim
Outliner file with the current roadmap and progress.

Set up Dist::Zilla to reduce technical debt and make releasing code
fun again.

=head1 COPYRIGHT AND LICCENSE

Copyright 2009-2010 by Rocco Caputo.

Reflex is free software.  You may redistribute and/or modify it under
the same terms as Perl itself.

TODO - Use the latest recommended best practice for licenses.

=cut
