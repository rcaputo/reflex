package ThingWithCallbacks;

use Moose;

# A demo class that delivers callbacks to its users.  I wanted to go even
# more abstract than Reflex::Interval, partly to reduce confusion over
# the callbacks subproject's scope.  Not all callback types are
# appropriate for timers, too.

use Reflex::Event;
use Reflex::Callbacks qw(gather_cb);

has cb => ( is => 'rw', isa => 'Reflex::Callbacks' );

# This is interesting code from Reflex::Interval.
#has on_tick => (
#	isa     => 'Reflex::Callback',
#	is      => 'ro',
#	coerce  => 1,
#	default => "tick",
#	default => sub {
#		my $self = shift;
#		Reflex::Callback::Emit->new(
#			object      => $self,
#			event_name  => "tick",
#		);
#	},
#);

sub BUILD {
	my ($self, $arg) = @_;

	# Gather the callbacks from the constructor parameters.
	$self->cb(gather_cb($self, $arg));
}

sub run {
	my $self = shift;
	$self->cb()->deliver(
		Reflex::Event->new( _name => "event", _emitters => [ $self ] )
	);
}

1;
