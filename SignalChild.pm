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

__PACKAGE__->_register_signal_params(qw(pid exit));

sub start_watching {
	my $self = shift;
	return unless $self->call_gate("start_watching");
	$POE::Kernel::poe_kernel->sig_child($self->pid(), "signal_happened");
}

sub stop_watching {
	my $self = shift;
	return unless $self->call_gate("stop_watching");
	$POE::Kernel::poe_kernel->sig_child($self->pid(), undef);
	$self->name(undef);
}

no Moose;
__PACKAGE__->meta()->make_immutable();

1;
