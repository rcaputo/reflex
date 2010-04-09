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
sub _deliver {
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

no Moose;
__PACKAGE__->meta()->make_immutable();

1;

__END__

=head1 NAME

Reflex::Timer - Observe the passage of time.

=head1 SYNOPSIS

# Not a complete program.  Many of the examples use Reflex::Timer.
# You can't throw a stone without hitting one.

	sub object_method {
		my ($self, $args) = @_;

		$self->timer(
			Reflex::Timer->new(
				interval => 1,
				auto_repeat => 1,
			)
		);
	);

=head1 DESCRIPTION

Reflex::Timer emits events to mark the passage of time.

Its constructor takes a hash as an argument. 
The interval specifies the interval between events are fired.
auto_repeat is either specified as 1 or not specified and in the former
case, the events will be fired repeatedly and in the latter, only one event
is fired.
event_name is a key in the hash that specifies what the event emitted should 
be called. 
TODO - Complete the API.  It's currently very incomplete.  It only
handles relative delays via its "interval" constructor parameter, and
automatic repeat via "auto_repeat".

TODO - Complete the documentation.

=head1 GETTING HELP

L<Reflex/GETTING HELP>

=head1 ACKNOWLEDGEMENTS

L<Reflex/ACKNOWLEDGEMENTS>

=head1 SEE ALSO

L<Reflex> and L<Reflex/SEE ALSO>

=head1 BUGS

L<Reflex/BUGS>

=head1 CORE AUTHORS

L<Reflex/CORE AUTHORS>

=head1 OTHER CONTRIBUTORS

L<Reflex/OTHER CONTRIBUTORS>

=head1 COPYRIGHT AND LICENSE

L<Reflex/COPYRIGHT AND LICENSE>

=cut
