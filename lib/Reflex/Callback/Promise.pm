package Reflex::Callback::Promise;

use Moose;
extends qw(Reflex::Callbacks Reflex::Callback);

has queue => (
	is      => 'rw',
	isa     => 'ArrayRef[ArrayRef]',
	default => sub { [] },
);

# Delivering to a promise enqueues the message.
sub deliver {
	my ($self, $event, $arg) = @_;
	push @{$self->queue()}, { name => $event, arg => $arg };
}

sub next {
	my $self = shift;

	my $queue = $self->queue();

	# TODO - Probably should bail out if the event loop ends.
	$POE::Kernel::poe_kernel->run_one_timeslice() while @$queue < 1;

	return shift @$queue;
}

1;

__END__

=head1 NAME

Reflex::Callback::Promise - Condvar-like non-callback adapter

=head1 SYNOPSIS

Used within Reflex:

	use Reflex::Timer;
	use ExampleHelpers qw(eg_say);

	my $pt = Reflex::Timer->new(
		interval    => 1 + rand(),
		auto_repeat => 1,
	);

	while (my $event = $pt->next()) {
		eg_say("promise timer returned an event (@$event)");
	}

Low-level usage:

	use Reflex::Callback::Promise;

	my $cb = Reflex::Callback::Promise->new();
	$cb->deliver( greet => { name => "world" } );

	my $event = $cb->next();
	print "event '$event->{name}': hello, $event->{arg}{name}\n";

=head1 DESCRIPTION

Reflex::Callback::Promise maps the generic Reflex::Callback interface
to non-callback promises, which are kind of like condvars.  In most
cases, Reflex::Callbacks' cb_promise() or other syntactic sweeteners
will be used instead of raw Reflex::Callback::Promise objects.

=head2 new

Reflex::Callback::Promise's constructor takes no parameters.  It
creates a promise queue that is populated by deliver() and drained by
next().  Furthermore, next() will block as necessary until it can
return an event.  This requires the help of some form of concurrency,
currently hardcoded to use POE.

A future version may delegate the POE dependency to a subclass.

=head2 next

Reflex::Callback::Promise's next() method retrieves the next pending
event held in the object's queue.  If the queue is empty, next() will
dispatch other events until some asynchronous code enqueues a new event
in the promise's queue.

=head2 deliver

Reflex::Callback::Promise's deliver() enqueues events for the promise.
As with other Reflex::Callback subclasses, this deliver() accepts two
positional parameters: an event name (which IS used), and a hashref of
named parameters to be passed to the callback.

Deliver doesn't return anything meaningful, since the code to handle
the event isn't executed at the time of delivery.

=head1 SEE ALSO

L<Reflex>
L<Reflex::Callback>
L<Reflex::Callbacks>

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
