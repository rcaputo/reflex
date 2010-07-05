package Reflex::SigCatcher;

use Moose;
extends 'Reflex::Base';

has signal => (
	is        => 'ro',
	isa       => 'Str',
	required  => 1,
);

has active => (
	is      => 'ro',
	isa     => 'Bool',
	default => 1,
);

with 'Reflex::Role::SigCatcher' => {
	signal        => 'signal',
	active        => 'active',
	cb_signal     => 'on_signal',
	method_start  => 'start',
	method_stop   => 'stop',
	method_pause  => 'pause',
	method_resume => 'resume',
};

1;

__END__

=head1 NAME

Reflex::SigCatcher - receive callbacks when signals arrive

=head1 SYNOPSIS

eg/eg-39-signals.pl

	use warnings;
	use strict;

	use Reflex::SigCatcher;
	use Reflex::Callbacks qw(cb_coderef);
	use ExampleHelpers qw(eg_say);

	eg_say("Process $$ is waiting for SIGUSR1 and SIGUSR2.");

	my $usr1 = Reflex::SigCatcher->new(
		signal    => "USR1",
		on_signal => cb_coderef { eg_say("Got SIGUSR1.") },
	);

	my $usr2 = Reflex::SigCatcher->new( signal => "USR2" );
	while ($usr2->next()) {
		eg_say("Got SIGUSR2.");
	}

=head1 DESCRIPTION

Reflex::SigCatcher waits for signals from the operating system.  It
may invoke callback functions and/or be used as a promise of new
signals depending on the application's needs.

Reflex::SigCatcher is almost entirely implemented in
Reflex::Role::SigCatcher.
That role's documentation contains important details that won't be
covered here.

Reflex::SigCatcher is not suitable for SIGCHLD use.  The specialized
Reflex::PidReaper class is used for that, and it will automatically
wait() for processes and return their exit statuses.

=head2 Public Attributes

=head3 signal

Reflex:SigCatcher's C<signal> attribute defines the name of the signal
to catch.  Names are as those in %SIG, namely with the leading "SIG"
scraped off.

=head3 active

The C<active> attribute controls whether the signal catcher will be
started in an actively catching state.  It defaults to true; set it to
false if you'd like to activate the signal catcher later.

=head2 Public Methods

=head3 start

Reflex::SigCatcher's start() method may be used to initialize signal
catchers and start them watching for signals.  start() will be called
automatically if the signal catcher is started in the active state,
which it is by default.

Signal catchers may not be stopped, paused or resumed until they have
been started.

=head3 stop

The stop() method stops and finalizes the signal catcher.  It's
automatically called at DEMOLISH time, just in case it hasn't already
been.

=head3 pause

pause() pauses the signal catcher without finalizing it.  This is a
lighter-weight, non-final version of stop().

=head3 resume

resume() resumes a paused signal catcher without re-initializing it.
This is a lighter-weight, non-initial version of start().

=head2 Callbacks

=head3 on_signal

The on_signal() callback notifies the user when the watched signal has
been caught.  It includes no parameters of note.

=head3 on_data

on_data() will be called whenever Reflex::Stream receives data.  It
will include one named parameter in $_[1], "data", containing raw
octets received from the stream.

	sub on_data {
		my ($self, $param) = @_;
		print "Got data: $param->{data}\n";
	}

The default on_data() callback will emit a "data" event.

=head3 on_error

on_error() will be called if an error occurs reading from or writing
to the stream's handle.  Its parameters are the usual for Reflex:

	sub on_error {
		my ($self, $param) = @_;
		print "$param->{errfun} error $param->{errnum}: $param->{errstr}\n";
	}

The default on_error() callback will emit a "error" event.
It will also call stopped().

When overriding this callback, please be sure to call stopped(), which
is provided by Reflex::Role::Collectible.  Calling stopped() is vital
for collectible objects to be released from memory when managed by
Reflex::Collection.

=head2 Public Events

Reflex::Stream emits stream-related events, naturally.

=head3 closed

The "closed" event indicates that the stream is closed.  This is most
often caused by the remote end of a socket closing their connection.

See L</on_closed> for more details.

=head3 data

The "data" event is emitted when a stream produces data to work with.
It includes a single parameter, also "data", containing the raw octets
read from the handle.

See L</on_data> for more details.

=head3 error

Reflex::Stream emits "error" when any of a number of calls fails.

See L</on_error> for more details.

=head1 EXAMPLES

eg/EchoStream.pm in the distribution is the same EchoStream that
appears in the SYNOPSIS.

eg/eg-38-promise-client.pl shows a lengthy inline usage of
Reflex::Stream and a few other classes.

=head1 SEE ALSO

L<Reflex>
L<Reflex::Role::SigCatcher>
L<Reflex::Role::PidReaper>
L<Reflex::PidReaper>

L<Reflex/ACKNOWLEDGEMENTS>
L<Reflex/ASSISTANCE>
L<Reflex/AUTHORS>
L<Reflex/BUGS>
L<Reflex/BUGS>
L<Reflex/CONTRIBUTORS>
L<Reflex/COPYRIGHT>
L<Reflex/LICENSE>
L<Reflex/TODO>

=cut
