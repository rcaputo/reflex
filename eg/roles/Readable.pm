package Readable;
use MooseX::Role::Parameterized;

use Scalar::Util qw(weaken);

parameter handle => (
	isa     => 'Str',
	default => 'handle',
);

parameter knob_suffix => (
	isa     => 'Str',
	default => '_rd',
);

parameter knob => (
	isa     => 'Str',
	default => sub {
		my $self = shift;
		$self->handle() . $self->knob_suffix();
	},
	lazy    => 1,
);

parameter select_method => (
	isa     => 'Str',
	default => 'select_read',
);

parameter event => (
	isa     => 'Str',
	default => 'readable',
);

parameter active => (
	isa     => 'Bool',
	default => 0,
);

role {
	my $p = shift;

	my $h = $p->handle();
	my $k = $p->knob();
	my $m = $p->select_method();
	my $e = $p->event();
	my $active = $p->active();
	my $trigger_name = "_${k}_changed";
	my $emit_name = "${h}_${e}";

	has $k => (
		is      => 'rw',
		isa     => 'Bool',
		default => $active,
		trigger => sub {
			my $self = shift;
			$self->$trigger_name(@_);
		},
		initializer => sub {
			my $self = shift;
			$self->$trigger_name(@_);
		},
	);

	method $trigger_name => sub  {
		my ($self, $value) = @_;

		# Must be run in the right POE session.
		return unless $self->call_gate($trigger_name, $value);

		# Turn on watcher.
		if ($value) {
			my $envelope = [ $self ];
			weaken $envelope->[0];
			$POE::Kernel::poe_kernel->$m(
				$self->$h(), 'select_ready', $envelope, $e, $emit_name
			);
			return;
		}

		# Turn off watcher.
		$POE::Kernel::poe_kernel->$m($self->$h(), undef);
	};

	# Turn off watcher during destruction.
	after DESTROY => sub {
		my $self = shift;
		$self->$k(0) if $self->$k();
	};

	# Part of the POE/Reflex contract.
	method _deliver => sub {
		my ($self, $handle, $mode, $event_name) = @_;
		$self->emit(
			event => $event_name,
			args => {
				handle => $handle,
			}
		);
	};
};

1;
