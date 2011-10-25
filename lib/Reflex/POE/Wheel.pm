package Reflex::POE::Wheel;
# vim: ts=2 sw=2 noexpandtab

use Moose;
extends 'Reflex::Base';
use Scalar::Util qw(weaken);
use POE::Wheel;

has wheel => (
	isa     => 'Maybe[POE::Wheel]',
	is      => 'rw',
);

my %wheel_id_to_object;

sub BUILD {
	my ($self, $args) = @_;

	my $wheel_class = $self->wheel_class();

	# Get rid of stuff we don't need.
	foreach my $param (keys %$args) {
		delete $args->{$param} unless exists $self->valid_params()->{$param};
	}

	# Map methods to events in the wheel parameters.
	my $events_to_indices = $self->events_to_indices();
	while (my ($wheel_param, $event_idx) = each %$events_to_indices) {
		$args->{$wheel_param} = "wheel_event_$event_idx";
	}

	$self->create_wheel($wheel_class, $args);
}

sub create_wheel {
	my ($self, $wheel_class, $args) = @_;

	return unless $self->call_gate("create_wheel", $wheel_class, $args);

	my $wheel = $wheel_class->new( %$args );
	$self->wheel($wheel);

	$wheel_id_to_object{$wheel->ID()} = $self;
	weaken $wheel_id_to_object{$wheel->ID()};
}

sub wheel_id {
	my $self = shift;
	return $self->wheel()->ID();
}

sub put {
	my $self = shift;
	$self->wheel()->put(@_);
}

sub DEMOLISH {
	my $self = shift;
	$self->demolish_wheel();
}

sub demolish_wheel {
	my $self = shift;
	return unless defined($self->wheel()) and $self->call_gate("demolish_wheel");
	delete $wheel_id_to_object{ $self->wheel_id() };
	$self->wheel(undef);
}

sub deliver {
	my ($class, $event_idx, @event_args) = @_;

	# Map parameter offsets to named parameters.
	my ($event_type, $event_name, @field_names) = $class->index_to_event(
		$event_idx
	);

	my $i = 0;
	my %event_args = map { $_ => $event_args[$i++] } @field_names;

	# Get the wheel that sent us an event.

	my $wheel_id = delete $event_args{wheel_id};
	delete $event_args{_discard_};

	# Get the Reflex::Base object that owns this wheel.

	my $self = $wheel_id_to_object{$wheel_id};
	die unless $self;

	# Emit the event.
	$self->emit(
		-name => $event_name,
		-type => $event_type,
		%event_args
	);
}

1;

__END__

=head1 NAME

Reflex::POE::Wheel - Base class for POE::Wheel wrappers.

=head1 SYNOPSIS

There is no concise synopsis at this time.  Setting up a new
Reflex::POE::Wheel is rather involved.  The source for
L<Reflex::POE::Wheel::Run> may serve as an example.

=head1 DESCRIPTION

Reflex::POE::Wheel is a base class for Reflex objects that wrap and
watch POE::Wheel objects.  Subclasses define a handful of methods
that describe the wheels they wrap.  Reflex::POE::Wheel will use the
configuration to validate constructor parameters, map wheel events to
Reflex events, and map positional callback parameters to named ones.

It's rather handy once you get used to it.

=head2 Public Attributes

=head3 wheel

Currently Reflex::POE::Wheel exposes the raw POE::Wheel via its
wheel() attribute.  This will be undefined if the wheel hasn't been
set up yet.

=head2 Public Methods

=head3 wheel_id

The wheel_id() method returns the ID of the POE::Wheel being managed.
C<< $foo->wheel()->ID() >> can also be used instead.

=head3 demolish_wheel

Cause the internal wheel to be demolished.  Provided as a method since
some wheels may require special handling.

=head3 put

put() sends its parameters to the POE::Wheel's put() method.

	$reflex_poe_wheel->put("one", "two");

=head2 Required Subclass Methods

These subclass methods are used to configure subclasses for their
chosen POE::Wheel objects.

=head3 event_to_index

event_to_index() maps POE::Wheel events to consecutive integer event
IDs.  event_emit_names() will provide Reflex-friendly event names
based on the event IDs.  event_param_names() will provide parameter
names that correspond to the wheel's positional parameters.

This mapping is from Reflex::POE::Wheel::Run.  It will make more sense
in the context of event_emit_names() and event_param_names().

	sub event_to_index {
		return(
			{
				StdinEvent  => 0,
				StdoutEvent => 1,
				StderrEvent => 2,
				ErrorEvent  => 3,
				CloseEvent  => 4,
			},
		);
	}

=head3 event_emit_names

event_emit_names() returns an array reference that maps
Reflex::POE::Wheel's event IDs to Reflex-friendly event names.

Here's an example from Reflex::POE::Wheel::Run.  The wheel's
StdinEvent (ID 0) is emitted as "stdin" (the 0th element in
event_emit_names()).  StdoutEvent becomes "stdout", and so on.

	sub event_emit_names {
		return(
			[
				'stdin',  # StdinEvent
				'stdout', # StdoutEvent
				'stderr', # StderrEvent
				'error',  # ErrorEvent
				'closed', # ClosedEvent
			],
		);
	}

=head3 event_param_names

event_param_names() returns an array reference that maps
Reflex::POE::Wheel's event IDs to Reflex-friendly lists of parameter
names.  The underlying POE::Wheel's positional parameters will be
mapped to these names before the Reflex object emits them.

Here's yet another example from Reflex::POE::Wheel::Run.  StdinEvent
and StdoutEvent each return two parameters.  The Reflex object will
emit their ARG0 as the named parameter "output", and ARG1 becomes the
named parameter "wheel_id".

	sub event_param_names {
		return(
			[
				[ "wheel_id" ],
				[ "output", "wheel_id" ],
				[ "output", "wheel_id" ],
				[ "operation", "errnum", "errstr", "wheel_id", "handle_name" ],
				[ "wheel_id" ],
			]
		);
	}

=head3 wheel_class

wheel_class() returns a simple string---the class name of the wheel to
construct.

=head3 valid_params

The valid_params() method returns a hash reference keyed on valid
constructor parameters.  Values don't matter at this time.
Reflex::POE::Wheel uses this hash reference to pre-validate
construction of underlying POE::Wheel objects.

POE::Wheel::Run takes quite a lot of parameters, most of which are
optional.

	sub valid_params {
		return(
			{
				CloseOnCall => 1,
				Conduit => 1,
				Filter => 1,
				Group => 1,
				NoSetPgrp => 1,
				NoSetSid => 1,
				Priority => 1,
				Program => 1,
				ProgramArgs => 1,
				StderrDriver => 1,
				StderrFilter => 1,
				StdinDriver => 1,
				StdinFilter => 1,
				StdioDriver => 1,
				StdioFilter => 1,
				StdoutDriver => 1,
				StdoutFilter => 1,
				User => 1,
			}
		);
	}

=head1 CAVEATS

The demolish() name is heading towards deprecation in favor of
something shorter and more widely recognized, perhaps stop().  The
jury is still out, however.

Methods are not yet converted automatically.  It seems more sensible
to provide a native Reflex::Base interface.  On the other hand, it
may be possible for Moose's "handles" attribute option to pass the
wheel's methods through the wrapper.  More investigation is required.

wheel() or wheel_id() will be deprecated, depending upon which is
considered redundant.

=head1 SEE ALSO

L<Moose::Manual::Concepts>

L<Reflex>
L<Reflex::POE::Event>
L<Reflex::POE::Postback>
L<Reflex::POE::Session>
L<Reflex::POE::Wheel::Run>

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
