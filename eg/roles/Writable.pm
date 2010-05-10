package Writable;
use MooseX::Role::Parameterized;

use Scalar::Util qw(weaken);

parameter handle => (
	isa     => 'Str',
	default => 'handle',
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
	my $active        = $p->active();

	my $cb_name       = $p->cb_ready();
	my $pause_name    = "pause_${h}_writable";
	my $resume_name   = "resume_${h}_writable";
	my $setup_name    = "_setup_${h}_writable";

	method $setup_name => sub {
		my ($self, $arg) = @_;

		# Must be run in the right POE session.
		return unless $self->call_gate($setup_name, $arg);

		my $envelope = [ $self ];
		weaken $envelope->[0];
		$POE::Kernel::poe_kernel->select_write(
			$self->$h(), 'select_ready', $envelope, $cb_name,
		);

		return if $active;

		$POE::Kernel::poe_kernel->select_pause_write($self->$h());
	};

	method $pause_name => sub {
		my $self = shift;
		$POE::Kernel::poe_kernel->select_pause_read($self->$h());
	};

	method $resume_name => sub {
		my $self = shift;
		$POE::Kernel::poe_kernel->select_resume_read($self->$h());
	};

	# Turn off watcher during destruction.
	after DEMOLISH => sub {
		my $self = shift;
		$POE::Kernel::poe_kernel->select_write($self->h(), undef);
	};

	# Part of the POE/Reflex contract.
	method _deliver => sub {
		my ($self, $handle, $cb_member) = @_;
		$self->$cb_member( { handle => $handle, } );
	};
};

1;
