package Reflex::POE::Event;
# vim: ts=2 sw=2 noexpandtab

use Moose;
use Carp qw(croak);

has object => (
	is        => 'ro',
	isa       => 'Reflex::Base',
	required  => 1,
);

has method => (
	is        => 'rw',
	isa       => 'Str',
	required  => 1,
);

has context => (
	is      => 'rw',
	isa     => 'HashRef',
	default => sub { {} },
);

sub BUILD {
	my $self = shift;

	if (
		$POE::Kernel::poe_kernel->get_active_session()->ID()
		ne
		$self->object()->session_id()
	) {
		croak(
			"When interfacing with POE at large, ", __PACKAGE__, " must\n",
			"be created within a Reflex::Base's session.  Perhaps invoke it\n",
			"within the object's run_within_session() method",
		);
	}
}

sub deliver {
	my ($self, $event) = @_;

	$POE::Kernel::poe_kernel->post(
		$self->object()->session_id(), "call_gate_method",
		$self->object(), $self->method(), {
			context   => $self->context(),
			response  => $event,
		}
	);
}

1;

__END__

=head1 NAME

Reflex::POE::Event - Communicate with POE components expecting events.

=head1 SYNOPSIS

This BUILD method is from eg-12-poco-event.pl in Reflex's eg
directory.  It's for an App (application) class that must request
service from a POE component by posting an event.

	sub BUILD {
		my $self = shift;
		$self->component( PoCoEvent->new() );

		# Make sure it runs within the object's POE::Session.
		$self->run_within_session(
			sub {
				$self->component->request(
					Reflex::POE::Event->new(
						object  => $self,
						method  => "on_component_result",
						context => { cookie => 123 },
					),
				);
			}
		);
	}

App's constructor runs within its creator's session, which may not be
the correct one to be sending the event.  run_within_session()
guarantees that Reflex::POE::Event is sent from the App, so that
responses will reach the App later.

An optional context (or continuation) may be stored with the event.
It will be returned to the callback as its "context" parameter.

=head1 DESCRIPTION

Reflex::POE::Event is a helper object for interacting with POE modules
that expect event names for callbacks.  It creates an object that may
be used as a POE event name.  Reflex routes these events to their
proper callbacks when POE sends them back.

Authors are encouraged to encapsulate POE interaction within Reflex
objects.  Most users should not need use Reflex::POE::Event (or other
Reflex::POE helpers) directly.

=head2 Public Attributes

=head3 object

"object" contains a reference to the object that will handle this
POE event.

=head3 method

"method" contains the name of the method that will handle this event.

=head3 context

Context optionally contains a hash reference of named values.  This
hash reference will be passed to the event's "context" callback
parameter.

=head2 Callback Parameters

Reflex::POE::Event provides some callback parameters for your
convenience.

=head3 context

The "context" parameter includes whatever was supplied to the event's
constructor.  Consider this event and its callback:

	my $event = Reflex::POE::Event->new(
		object => $self,
		method => "callback",
		context => { abc => 123 },
	);

	sub callback {
		my ($self, $event) = @_;
		print(
			"Our context: ", $event->context()->{abc}, "\n",
			"POE args: @{$event->response()}\n"
		);
	}

=head3 response

POE events often include additional positional parameters in POE's
C<ARG0..$#_> offsets.  These are provided as an array reference in the
callback's "response" parameter.  An example is shown in the
documentation for the "context" callback parameter.

=head1 CAVEATS

Reflex::POE::Event objects must pass through POE unscathed.  POE's
basic Kernel and Session do this, but rare third-party modules may
stringify or otherwise modify event names.  If you encounter one,
please let the author know.

Reflex::POE::Event's implementation may change.  For example, it may
generate strings at a later date, if such strings can fulfill all the
needs of the current object-based implementation.

Reflex::POE::Event's interface may change significantly now that we
have Reflex::Callbacks.  The main change would be to support generic
callbacks rather than hardcode for method dispatch.

=head1 SEE ALSO

L<Moose::Manual::Concepts>

L<Reflex>
L<Reflex::POE::Postback>
L<Reflex::POE::Session>
L<Reflex::POE::Wheel::Run>
L<Reflex::POE::Wheel>

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
