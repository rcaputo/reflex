package Reflex::Role::Interval;
# vim: ts=2 sw=2 noexpandtab

use Reflex::Role;
use Scalar::Util qw(weaken);

attribute_parameter att_auto_repeat => "auto_repeat";
attribute_parameter att_auto_start  => "auto_start";
attribute_parameter att_interval    => "interval";
callback_parameter  cb_tick         => qw( on att_interval tick );
method_parameter    method_repeat   => qw( repeat att_interval _ );
method_parameter    method_start    => qw( start att_interval _ );
method_parameter    method_stop     => qw( stop att_interval _ );

role {
	my $p = shift;

	my $att_auto_repeat = $p->att_auto_repeat();
	my $att_auto_start  = $p->att_auto_start();
	my $att_interval    = $p->att_interval();
	my $cb_tick         = $p->cb_tick();

	requires $att_interval, $cb_tick;

	has $att_auto_repeat => ( is => 'ro', isa => 'Bool', default => 1 );
	has $att_auto_start  => ( is => 'ro', isa => 'Bool', default => 1 );

	my $method_repeat   = $p->method_repeat();
	my $method_stop     = $p->method_stop();

	my $timer_id_name   = "${att_interval}_timer_id";

	has $timer_id_name => (
		isa => 'Maybe[Str]',
		is  => 'rw',
	);

	# Work around a Moose edge case.
	sub BUILD {}

	after BUILD => sub {
		my ($self, $args) = @_;
		$self->$method_repeat() if $self->$att_auto_start();
	};

	method $method_repeat => sub {
		my ($self, $args) = @_;

		# Switch to the proper session.
		return unless (
			defined $self->$att_interval() and $self->call_gate($method_repeat)
		);

		# Stop a previous alarm.
		$self->$method_stop() if defined $self->$timer_id_name();

		# Put a weak $self in an envelope that can be passed around
		# without strenghtening the object.

		my $envelope = [ $self, $cb_tick ];
		weaken $envelope->[0];

		$self->$timer_id_name(
			$POE::Kernel::poe_kernel->delay_set(
				'timer_due',
				$self->$att_interval(),
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

	after $cb_tick => sub {
		my ($self, $args) = @_;
		$self->$method_repeat() if $self->$att_auto_repeat();
	};
};

1;

__END__

=head1 NAME

Reflex::Role::Interval - set a periodic, recurring timer

=head1 SYNOPSIS

	package Reflex::Interval;

	use Moose;
	extends 'Reflex::Base';

	has interval    => ( isa => 'Num', is  => 'ro' );
	has auto_repeat => ( isa => 'Bool', is => 'ro', default => 1 );
	has auto_start  => ( isa => 'Bool', is => 'ro', default => 1 );

	with 'Reflex::Role::Interval' => {
		interval      => "interval",
		auto_start    => "auto_start",
		auto_repeat   => "auto_repeat",
		cb_tick       => "on_tick",
		method_start  => "start",
		method_stop   => "stop",
		method_repeat => "repeat",
	};

	1;

=head1 DESCRIPTION

Reflex::Role::Interval adds a periodic timer and callback to a class.
It's parameterized, so it can be consumed multiple times to add more
than one interval timer to the same class.

In the SYNOPSIS, the Reflex::Interval class consumes a single
Reflex::Role::Interval.  Reflex::Interval provides some data in the
form of interval(), auto_repeat() and auto_start().  The role provides
a callback to the on_tick() method, which is also provided by the
role.  The role also provides some control methods, start(), stop()
and repeat().

The general rules and conventions for Reflex paramaeterized roles are
covered in L<Reflex::Role>.

=head2 Attribute Parameters

Attribute parameters specify the names of attributes in the consumer
that control the role's behavior.

=head3 interval

C<interval> names an attribute in the consumer that must hold the
role's interval, in seconds.  The role will trigger a callback
every interval() seconds, if the C<auto_repeat> attribute is true.

C<interval> is a Reflex::Role "key" attribute.  The interval
attribute's name is used in the default names for the role's internal
and public attributes, methods and callbacks.

=head3 auto_repeat

Interval timers will repeat automatically if the value of the
attribute named in C<auto_repeat> is true.  Otherwise, repeat() must
be called to trigger the next interval callback, C<interval> seconds
after repeat() is called.

=head3 auto_start

Interval timers will automatically start if the value of the attribute
named in C<auto_start> is true.  Otherwise, the class consuming this
role must call the role's start method, named in C<method_start>.

=head2 Callback Parameters

Callback parameters specify the names of methods in the consumer that
will be called when the role notifies the class of events.

=head3 cb_tick

C<cb_tick> sets the name of the tick callback method, which must be
implemented by this role's consumer.  C<cb_tick> is optional, and will
default to the catenation of "on_", the name of the interval
attribute, and "_tick".

Reflex::Role::Interval provides a default callback that will emit the
"tick" event and repeat the timer if C<<$self->$auto_repeat()>>
evaluates to true.

=head2 Method Parameters

Method parameters generally specify the names of methods the role will
provide to modify the role's behavior.

=head3 method_repeat

Reflex::Role::Interval provides a method to manually trigger
repetition of the interval timer.  This method exists in case
C<auto_repeat> evaluates to false.  The repeat method name may be
overridden by C<method_repeat>'s value.  By default, the repeat method
will be "repeat_" prepended to the name of the interval attribute.

=head3 method_start

Reflex::Role::Interval provides a method to start the interval timer,
which is vital for cases when C<auto_start> evaluates to false.  The
start method name may be overridden by C<method_start>'s value.  By
default, the start method will be "start_" prepended to the name of
the interval attribute.

=head3 method_stop

Reflex::Role::Interval provides a method to stop the interval timer.
This method will be flattened into the consuming class, per Moose.
C<method_stop> allows the role's consumer to define the name of that
method.  By default, the stop method's name will be "stop_" prepended
to the name of the interval attribute.

=head1 EXAMPLES

L<Reflex::Timeout> is one example of using Reflex::Role::Timeout.

=head1 SEE ALSO

L<Reflex>
L<Reflex::Interval>
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
