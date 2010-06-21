package Reflex::Role::Readable;
use MooseX::Role::Parameterized;

# TODO - Reflex::Role::Readable and Writable are nearly identical.
# Can they be abstracted further?

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
		"on_" . $self->handle() . "_readable";
	},
	lazy      => 1,
);

role {
	my $p = shift;

	my $h = $p->handle();
	my $active = $p->active();

	my $cb_name = $p->cb_ready();
	my $pause_name    = "pause_${h}_readable";
	my $resume_name   = "resume_${h}_readable";
	my $setup_name    = "_setup_${h}_readable";

	method $setup_name => sub {
		my ($self, $arg) = @_;

		# Must be run in the right POE session.
		return unless $self->call_gate($setup_name, $arg);

		my $envelope = [ $self ];
		weaken $envelope->[0];
		$POE::Kernel::poe_kernel->select_read(
			$self->$h(), 'select_ready', $envelope, $cb_name,
		);

		return if $active;

		$POE::Kernel::poe_kernel->select_pause_read($self->$h());
	};

	method $pause_name => sub {
		my $self = shift;
		$POE::Kernel::poe_kernel->select_pause_read($self->$h());
	};

	method $resume_name => sub {
		my $self = shift;
		$POE::Kernel::poe_kernel->select_resume_read($self->$h());
	};

	after BUILD => sub {
		my ($self, $arg) = @_;
		$self->$setup_name($arg);
	};

	# Turn off watcher during destruction.
	after DEMOLISH => sub {
		my $self = shift;
		$POE::Kernel::poe_kernel->select_read($self->h(), undef);
	};

	# Part of the POE/Reflex contract.
	method deliver => sub {
		my ($self, $handle, $cb_member) = @_;
		$self->$cb_member( { handle => $handle, } );
	};
};

1;
