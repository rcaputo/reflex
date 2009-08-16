package SignalChild;

use Moose;
extends qw(Signal);

has '+name' => (
	default => 'CHLD',
);

has 'pid' => (
	isa       => 'Int',
	is        => 'ro',
	required  => 1,
	default   => sub { die "required" },
);

sub event_param_names {
	return [qw(pid exit)];
}

sub start_watching {
	my $self = shift;

	return $POE::Kernel::poe_kernel->call(
		$self->session_id(), "call_gate", $self, "start_watching", @_
	) if (
		$self->session_id() ne $POE::Kernel::poe_kernel->get_active_session()->ID()
	);

	$POE::Kernel::poe_kernel->sig_child($self->pid(), "signal_happened");
}

sub stop_watching {
	my $self = shift;

	return $POE::Kernel::poe_kernel->call(
		$self->session_id(), "call_gate", $self, "stop_watching", @_
	) if (
		$self->session_id() ne $POE::Kernel::poe_kernel->get_active_session()->ID()
	);

	$POE::Kernel::poe_kernel->sig_child($self->pid(), undef);
	$self->name(undef);
}

1;

