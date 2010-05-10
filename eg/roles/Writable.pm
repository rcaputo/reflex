package Writable;
use MooseX::Role::Parameterized;

use Scalar::Util qw(weaken);

parameter handle => (
	isa     => 'Str',
	default => 'handle',
);

parameter knob => (
	isa     => 'Str',
	default => sub { my $self = shift; $self->handle() . '_wr'; },
	lazy    => 1,
);

parameter active => (
	isa     => 'Bool',
	default => 0,
);

parameter cb_ready => (
	isa       => 'Str',
	default   => sub {
		my $self = shift;
		"on_" . $self->handle() . "_writable";
	},
	lazy      => 1,
);

role {
	my $p = shift;

	my $h             = $p->handle();
	my $k             = $p->knob();
	my $active        = $p->active();
	my $trigger_name  = "_${k}_changed";
	my $cb_name       = $p->cb_ready();

	my $trigger_coderef = sub { my $self = shift; $self->$trigger_name(@_) };

	has $k => (
		is          => 'rw',
		isa         => 'Bool',
		default     => $active,
		trigger     => $trigger_coderef,
		initializer => $trigger_coderef,
	);

	method $trigger_name => sub  {
		my ($self, $value) = @_;

		# TODO - Use pause/resume here.

		# Must be run in the right POE session.
		return unless $self->call_gate($trigger_name, $value);

		# Turn on watcher.
		if ($value) {
			my $envelope = [ $self ];
			weaken $envelope->[0];
			$POE::Kernel::poe_kernel->select_write(
				$self->$h(), 'select_ready', $envelope, $cb_name,
			);
			return;
		}

		# Turn off watcher.
		$POE::Kernel::poe_kernel->select_write($self->$h(), undef);
	};

	# Turn off watcher during destruction.
	after DESTROY => sub {
		my $self = shift;
		$self->$k(0) if $self->$k();
	};

	# Part of the POE/Reflex contract.
	method _deliver => sub {
		my ($self, $handle, $cb_member) = @_;
		$self->$cb_member( { handle => $handle, } );
	};
};

1;
