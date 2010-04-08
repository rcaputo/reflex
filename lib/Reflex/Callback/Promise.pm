package Reflex::Callback::Promise;

use Moose;
extends 'Reflex::Callback';
extends 'Reflex::Callbacks';

has queue => (
	is      => 'rw',
	isa     => 'ArrayRef[ArrayRef]',
	default => sub { [] },
);

# Delivering to a promise enqueues the message.
sub deliver {
	my ($self, $event, $arg) = @_;
	push @{$self->queue()}, [ $event, $arg ];
}

sub wait {
	my $self = shift;

	my $queue = $self->queue();

	# TODO - Probably should bail out if the event loop ends.
	$POE::Kernel::poe_kernel->run_one_timeslice() while @$queue < 1;

	return shift @$queue;
}

1;
