package Reflex::Role::Wakeup;
use Reflex::Role;
use Scalar::Util qw(weaken);

attribute_parameter name        => "name";
attribute_parameter when        => "when";

method_parameter    method_stop   => qw( stop name _ );
method_parameter    method_reset  => qw( reset name _ );
callback_parameter  cb_wakeup     => qw( on name wakeup );

role {
	my $p = shift;

	my $role_name     = $p->name();

	my $timer_id_name = "${role_name}_timer_id";

	my $method_reset  = $p->method_reset();
	my $method_stop   = $p->method_stop();
	my $when          = $p->when();
	my $cb_wakeup     = $p->cb_wakeup();

	has $timer_id_name => (
		isa => 'Maybe[Str]',
		is  => 'rw',
	);

	# Work around a Moose edge case.
	sub BUILD {}

	after BUILD => sub {
		my ($self, $args) = @_;
		$self->$method_reset($self->$when());
	};

	method $method_reset => sub {
		my ($self, $args) = @_;

		# Switch to the proper session.
		return unless (
			defined $self->$when() and $self->call_gate($method_reset)
		);

		# Stop a previous alarm.
		$self->$method_stop() if defined $self->$timer_id_name();

		# Put a weak $self in an envelope that can be passed around
		# without strenghtening the object.

		my $envelope = [ $self, $cb_wakeup ];
		weaken $envelope->[0];

		$self->$timer_id_name(
			$POE::Kernel::poe_kernel->alarm_set(
				'timer_due',
				$self->$when(),
				$envelope,
			)
		);
	};

	after DEMOLISH => sub {
		my ($self, $args) = @_;
		$self->$method_stop();
	};

	method $method_stop => sub {
		my ($self, $args) = @_;

		# Return if it was a false "alarm" (pun intended).
		return unless defined $self->$timer_id_name() and $self->call_gate("stop");

		$POE::Kernel::poe_kernel->alarm_remove($self->$timer_id_name());
		$self->$timer_id_name(undef);
	};

	method $cb_wakeup => sub {
		my ($self, $args) = @_;
		$self->emit(event => "time", args => $args);
		$self->$method_stop();
	};
};

1;
