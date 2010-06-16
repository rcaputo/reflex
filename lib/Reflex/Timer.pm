package Reflex::Timer;

use Moose;
extends qw(Reflex::Object);
use Scalar::Util qw(weaken);

has interval => (
	isa => 'Num',
	is => 'rw',
);

has alarm_id => (
	isa => 'Str|Undef',
	is => 'rw',
);

has auto_repeat => (
	isa => 'Bool',
	is => 'rw',
);

sub BUILD {
	my $self = shift;
	$self->repeat();
}

sub repeat {
	my $self = shift;

	#return unless interval specified
	return unless defined $self->interval() and $self->call_gate("repeat");

	# Stop a previous alarm?

	$self->stop() if defined $self->alarm_id();

	# Put a weak $self in an envelope that can be passed around.

	my $envelope = [ $self ];
	weaken $envelope->[0];

	$self->alarm_id(
		$POE::Kernel::poe_kernel->delay_set(
			'timer_due',
			$self->interval(),
			$envelope,
		)
	);
}

#overriden method from Reflex::Object
sub deliver {
	my $self = shift;
	$self->alarm_id(0);
	$self->emit( event => "tick" );
	$self->repeat() if $self->auto_repeat();
}

sub DEMOLISH {
	my $self = shift;
	$self->stop();
}

sub stop {
	my $self = shift;

	#return if it was a false "alarm" (pun intended)
	return unless defined $self->alarm_id() and $self->call_gate("stop");

	$POE::Kernel::poe_kernel->alarm_remove($self->alarm_id());
	$self->alarm_id(undef);
}

1;

__END__

=head1 NAME

Reflex::Timer - An object that watches the passage of time.

=head1 SYNOPSIS

	# Several examples in the eg directory use Reflex::Timer.

	use warnings;
	use strict;

	use lib qw(../lib);

	use Reflex::Timer;

	my $t = Reflex::Timer->new(
		interval    => 1,
		auto_repeat => 1,
	);

	while (my $event = $t->next()) {
		print "next() returned an event (@$event)\n";
	}

=head1 DESCRIPTION

Reflex::Timer emits events to mark the passage of time.  Its interface
is new and small.  Please contact the Reflex project if you need other
features, or send us a pull request at github or gitorious.

=head1 PUBLIC ATTRIBUTES

=head2 interval

Define the interval between creation and the "tick" event's firing.
If auto_repeat is also set, this becomes the interval between
recurring "tick" events.

=head2 auto_repeat

A Boolean value.  When true, Reflex::Timer will repeatedly fire "tick"
events every interval seconds.

=head1 PUBLIC EVENTS

=head2 tick

Reflex::Timer emits "tick" events.  We're looking for a better name,
so this may change in the future.  Your suggestions can help solidify
the interface quicker.

=head1 SEE ALSO

L<Reflex>

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
