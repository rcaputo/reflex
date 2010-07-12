package Reflex::Role::Wakeup;
use Reflex::Role;
use Scalar::Util qw(weaken);

attribute_parameter when          => "when";

method_parameter    method_stop   => qw( stop when _ );
method_parameter    method_reset  => qw( reset when _ );
callback_parameter  cb_wakeup     => qw( on when wakeup );

role {
	my $p = shift;

	my $when          = $p->when();

	my $timer_id_name = "${when}_timer_id";

	my $method_reset  = $p->method_reset();
	my $method_stop   = $p->method_stop();
	my $cb_wakeup     = $p->cb_wakeup();

	has $timer_id_name => (
		isa => 'Maybe[Str]',
		is  => 'rw',
	);

	# Work around a Moose edge case.
	sub BUILD {}

	after BUILD => sub {
		my ($self, $args) = @_;
		$self->$method_reset( { when => $self->$when() } );
	};

	method $method_reset => sub {
		my ($self, $args) = @_;

		# Switch to the proper session.
		return unless (
			defined $self->$when() and $self->call_gate($method_reset)
		);

		# If the args include "when", then let's reset when().
		$self->$when( $args->{when} ) if exists $args->{when};

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

__END__

=head1 NAME

Reflex::Role::Wakeup - set a wakeup callback for a particular UNIX time

=head1 SYNOPSIS

	package Reflex::Wakeup;

	use Moose;
	extends 'Reflex::Base';

	has when => ( isa => 'Num', is  => 'rw' );

	with 'Reflex::Role::Wakeup' => {
		when          => "when",
		cb_wakeup     => "on_time",
		method_stop   => "stop",
		method_reset  => "reset",
	};

	1;

=head1 DESCRIPTION

Reflex::Role::Wakeup is a parameterized role.  Each time it's
consumed, it adds another non-blocking wakeup callback to a class.
These callback will be invoked at particular UNIX times, established
by the contents of the "when" attributes named at composition time.

Reflex::Wakeup in the SYNOPSIS consumes a single Reflex::Role::Wakeup.
The parameters define the names of attributes that control the timer's
behavior, the names of callback methods, and the names of methods that
manipulate the timer.

=head2 Required Role Parameters

None.  All role parameters have defaults.

=head2 Optional Role Parameters

=head3 when

C<when> names an attribute in the consumer that must hold the role's
wakeup time.  Wakeup times are specified as seconds since the UNIX
epoch.  Reflex usually supports fractional seconds, but this
ultimately depends on the event loop being used.

Refex::Role::Wakeup uses the attribute name in C<when> to
differentiate between multiple applications of the same role to the
same class.  Reflex roles are building blocks of program behavior, and
it's reasonable to expect a class to need multiple building blocks of
the same type.  For instance, multiple wakeup timers for different
purposes.

=head3 method_stop

Reflex::Role::Wakeup will provide a method to stop the timer.  This
method will become part of the consuming class, per Moose.
C<method_stop> allows the consumer to define the name of that method.
By default, the method will be named:

	$method_stop = "stop_" . $when_name;

where $when_name is the attribute name supplied by the C<when>
parameter.

The stop method neither takes parameters nor returns anything.

=head3 method_reset

C<method_reset> allows the role's consumer to override the default
reset method name.  The default is C<"stop_${when_name}">, where
$when_name is the attribute name provided in the C<when> parameter.

All Reflex methods accept a hashref of named parameters.  Currently
the reset method accepts one named parameter, "when".  The value of
"when" must be the new time to trigger a callback.  If "when" isn't
provided, the wakeup callback will happen at the previous time set by
this module.

	$self->reset_name( { when => time() + 60 } );

One may also set the when() attribute and reset() the timer as two
distinct calls.

	$self->time( time() + 60 );  # 60 seconds from now
	$self->reset_time();

=head3 cb_wakeup

C<cb_wakeup> overrides the default method name that will be called
when the "when" time arrives.  The default is
"on_${when_name}_wakeup".

These callbacks receive no paramaters.

=head1 EXAMPLES

L<Reflex::Wakeup> is one example of using Reflex::Role::Wakeup.

=head1 SEE ALSO

L<Reflex>
L<Reflex::Wakeup>
L<Reflex::Role>

L<Reflex/ACKNOWLEDGEMENTS>
L<Reflex/ASSISTANCE>
L<Reflex/AUTHORS>
L<Reflex/BUGS>
L<Reflex/BUGS>
L<Reflex/CONTRIBUTORS>
L<Reflex/COPYRIGHT>
L<Reflex/LICENSE>
L<Reflex/TODO>

=cut
