package Reflex::Role::Timeout;
use Reflex::Role;
use Scalar::Util qw(weaken);

attribute_parameter name  => "name";
attribute_parameter delay => "delay";

method_parameter    method_stop   => qw( stop name _ );
method_parameter    method_start  => qw( start name _ );
method_parameter    method_reset  => qw( reset name _ );

callback_parameter  cb_timeout    => qw( on name done );

parameter active => (
	isa     => 'Bool',
	default => 1,
);

role {
	my $p = shift;

	my $role_name = $p->name();

	my $timer_id_name = "${role_name}_timer_id";
	my $method_start  = $p->method_start();
	my $method_stop   = $p->method_stop();
	my $method_reset  = $p->method_reset();
	my $cb_timeout    = $p->cb_timeout();

	has $timer_id_name => (
		isa => 'Maybe[Str]',
		is  => 'rw',
	);

	# Work around a Moose edge case.
	sub BUILD {}

	after BUILD => sub {
		my ($self, $args) = @_;
		$self->$method_start();
	};

	my $code_start = sub {
		my ($self, $args) = @_;

		# Switch to the proper session.
		return unless $self->call_gate($method_start);

		# Stop a previous alarm.
		$self->$method_stop() if defined $self->$timer_id_name();

		# Put a weak $self in an envelope that can be passed around
		# without strenghtening the object.

		my $envelope = [ $self, $cb_timeout ];
		weaken $envelope->[0];

		$self->$timer_id_name(
			$POE::Kernel::poe_kernel->delay_set(
				'timer_due',
				$self->delay(),
				$envelope,
			)
		);
	};

	method $method_start => $code_start;
	method $method_reset => $code_start;

	after DEMOLISH => sub {
		my ($self, $args) = @_;
		$self->$method_stop();
	};

	method $method_stop => sub {
		my ($self, $args) = @_;

		# Return if it was a false "alarm" (pun intended).
		return unless (
			defined $self->$timer_id_name() and $self->call_gate($method_stop)
		);

		$POE::Kernel::poe_kernel->alarm_remove($self->$timer_id_name());
		$self->$timer_id_name(undef);
	};

	method_emit $cb_timeout => "done";
};

1;
