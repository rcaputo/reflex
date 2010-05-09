package Readable;
use MooseX::Role::Parameterized;

use Scalar::Util qw(weaken);

parameter handle => (
	isa     => 'Str',
	default => 'handle',
);

parameter knob => (
	isa     => 'Str',
	default => sub { my $self = shift; $self->handle() . '_rd'; },
	lazy    => 1,
);

parameter active => (
	isa     => 'Bool',
	default => 0,
);

parameter cb => (
	isa       => 'Str',
	default   => sub {
		my $self = shift;
		"on_" . $self->handle() . "_readable";
	},
	lazy      => 1,
);

role {
	my $p = shift;

	my $h = $p->handle();
	my $k = $p->knob();
	my $active = $p->active();
	my $trigger_name = "_${k}_changed";
	my $cb_name = $p->cb();

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
			$POE::Kernel::poe_kernel->select_read(
				$self->$h(), 'select_ready', $envelope, $cb_name,
			);
			return;
		}

		# Turn off watcher.
		$POE::Kernel::poe_kernel->select_read($self->$h(), undef);
	};

	# Turn off watcher during destruction.
	after DESTROY => sub {
		my $self = shift;
		$self->$k(0) if $self->$k();
	};

	# Part of the POE/Reflex contract.
	method _deliver => sub {
		my ($self, $handle, $cb_member) = @_;
		$self->$cb_member(
			{
				handle => $handle,
			}
		);
	};
};

1;
