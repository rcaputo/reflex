package Reflex::POE::Wheel::Run;
# vim: ts=2 sw=2 noexpandtab

use Moose;
extends 'Reflex::POE::Wheel';
use POE::Wheel::Run;
use Reflex::PID;
use Reflex::Trait::Watched qw(watches);

# TODO - Bored now.  use Reflex::Event qw(Flushed Octets Error EOF); ???

use Reflex::Event::Flushed;
use Reflex::Event::Octets;
use Reflex::Event::Error;
use Reflex::Event::EOF;

# These are class methods, returning static class data.
# TODO - What's the proper way to do this with Moose?

my %event_to_index = (
	StdinEvent  => 0,
	StdoutEvent => 1,
	StderrEvent => 2,
	ErrorEvent  => 3,
	CloseEvent  => 4,
);

sub events_to_indices {
	return \%event_to_index;
}

my @index_to_event = (
	[ 'Reflex::Event::Flushed', 'stdin', 'wheel_id' ],
	[ 'Reflex::Event::Octets', 'stdout', 'octets', 'wheel_id' ],
	[ 'Reflex::Event::Octets', 'stderr', 'octets', 'wheel_id' ],
	[
		'Reflex::Event::Error', 'error', 'function', 'number', 'string', 'wheel_id'
	],
	[ 'Reflex::Event::EOF', 'closed', 'wheel_id' ],
);

sub index_to_event {
	my ($class, $index) = @_;
	return @{$index_to_event[$index]};
}

sub wheel_class {
	return 'POE::Wheel::Run';
}

sub valid_params {
	return(
		{
			CloseOnCall => 1,
			Conduit => 1,
			Filter => 1,
			Group => 1,
			NoSetPgrp => 1,
			NoSetSid => 1,
			Priority => 1,
			Program => 1,
			ProgramArgs => 1,
			StderrDriver => 1,
			StderrFilter => 1,
			StdinDriver => 1,
			StdinFilter => 1,
			StdioDriver => 1,
			StdioFilter => 1,
			StdoutDriver => 1,
			StdoutFilter => 1,
			User => 1,
		}
	);
}

# Also handle signals.

watches sigchild_watcher => (
	isa   => 'Maybe[Reflex::PID]',
	role  => 'sigchld',
);

sub BUILD {
	my $self = shift;

	$self->sigchild_watcher(
		Reflex::PID->new(pid => $self->wheel()->PID())
	);
}

# Rethrow our signal event.
sub on_sigchld_exit {
	my ($self, $event) = @_;
	$self->re_emit( $event, -name => 'signal' );
}

sub kill {
	my $self = shift;
	$self->wheel()->kill(@_);
}

1;

__END__

=head1 NAME

Reflex::POE::Wheel::Run - Represent POE::Wheel::Run as a Reflex class.

=head1 SYNOPSIS

Unfortunately there isn't a concise, completely executable example for
the synopsis at this time.  Please see eg-07-wheel-run.pl and
eg-08-watched-trait.pl in the distribution's eg directory for longer
but fully executable ones.

	watches child => (
		isa => 'Reflex::POE::Wheel::Run|Undef',
	);

	sub BUILD {
		my $self = shift;
		$self->child(
			Reflex::POE::Wheel::Run->new(
				Program => "$^X -wle 'print qq[pid(\$\$) moo(\$_)] for 1..10; exit'",
			)
		);
	}

	sub on_child_stdout {
		my ($self, $event) = @_;
		print "stdout: ", $event->output(), "\n";
	}

	sub on_child_close {
		my ($self, $event) = @_;
		print "child closed all output\n";
	}

	sub on_child_signal {
		my ($self, $event) = @_;
		print "child ", $event->pid(), " exited: ", $event->exit(), "\n";
		$self->child(undef);
	}

=head1 DESCRIPTION

Reflex::POE::Wheel::Run represents an enhanced POE::Wheel::Run object.
It will manage a child process, and it will also wait for (and report
on) the corresponding SIGCHLD.

This module delegates to L<POE::Wheel::Run> for most of its
implementation.  Please refer to that module for implementation
details.

=head2 Public Methods

This class adds public methods specific to POE::Wheel::Run's
operation.  However, common methods like put() are both implemented
and documented in the base L<Reflex::POE::Wheel> class.

=head3 kill

kill() passes its arguments to POE::Wheel::Run's kill() method.

=head2 Public Events

Objects of this class emit all of POE::Wheel::Run's events, albeit
renamed into Reflex-friendly forms.  Generally these forms are
determined by removing the "Event" suffix and lowercasing what
remains.  POE::Wheel::Run's StdinEvent becomes "stdin", and so on.

=head3 stdin

See POE::Wheel::Run's StdinEvent.  Within Reflex, this event comes
with only one parameter: "wheel_id".  This is the POE::Wheel::Run
object's ID.

=head3 stdout

See POE::Wheel::Run's StdoutEvent.  Reflex includes two parameters:
"wheel_id" and "output".  The latter parameter contains data the child
process wrote to its STDOUT handle.

=head3 stderr

See POE::Wheel::Run's StderrEvent.  Reflex includes two parameters:
"wheel_id" and "output".  The latter parameter contains data the child
process wrote to its STDERR handle.

=head3 error

See POE::Wheel::Run's ErrorEvent.  Reflex maps the wheel's parameters
to: "operation", "errnum", "errstr", "wheel_id" and "handle_name",
respectively.

=head3 closed

See POE::Wheel::Run's CloseEvent.  Reflex includes only one parameter
for this event: "wheel_id".

=head1 CAVEATS

This class could further be improved so that it doesn't report SIGCHLD
until all the child's output has been received and processed.  This
would resolve a long-standing nondeterminism in the timing of
on_child_close() vs. on_child_signal().

=head1 SEE ALSO

L<Moose::Manual::Concepts>

L<Reflex>
L<Reflex::POE::Event>
L<Reflex::POE::Postback>
L<Reflex::POE::Session>
L<Reflex::POE::Wheel>

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
