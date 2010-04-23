package Reflex::POE::Postback;

# TODO - Not Moose, unless Moose allows us to create blessed coderefs.

use warnings;
use strict;
use Scalar::Util qw(weaken);

my %owner_session_ids;

sub new {
	my ($class, $object, $method, $context) = @_;

	# TODO - Object owns component, which owns object?
	weaken $object;

	my $self = bless sub {
		$POE::Kernel::poe_kernel->post(
			$object->session_id(), "call_gate_method", $object, $method, {
				context   => $context,
				response  => [ @_ ],
			},
		);
	}, $class;

	$owner_session_ids{$self} = $object->session_id();
	$POE::Kernel::poe_kernel->refcount_increment(
		$object->session_id(), "reflex_postback"
	);

	# Double indirection sucks, but some libraries (like Tk) bless their
	# callbacks.  If we returned our own blessed callback, they would
	# alter the class and thwart DESTROY.
	#
	# TODO - POE::Session only does this when Tk is loaded.  I opted
	# against it here because the set of libraries that bless their
	# callbacks may grow over time.

	return sub { $self->(@_) };
}

sub DESTROY {
	my $self = shift;

	my $session_id = delete $owner_session_ids{$self};
	return unless defined $session_id;
	$POE::Kernel::poe_kernel->refcount_decrement(
		$session_id, "reflex_postback"
	);

	undef;
}

1;

__END__

=head1 NAME

Reflex::POE::Postback - Communicate with POE components expecting postbacks.

=head1 SYNOPSIS

Not a complete example.  Please see eg-11-poco-postback.pl in the eg
directory for a complete working program.

	my $postback = Reflex::POE::Postback->new(
		$self, "on_component_result", { cookie => 123 }
	);

=head1 DESCRIPTION

Reflex::POE::Postback creates an object that's substitutes for
POE::Session postbacks.  When invoked, however, they sent events back
to the object and method (and with optional continuation data)
provided during construction.

Reflex::POE::Postback was designed to interact with POE modules that
want to respond via caller-provided postbacks.  Authors are encouraged
to encapsulate POE interaction within Reflex objects.  Most users
should therefore not need use Reflex::POE::Postback (or other
Reflex::POE helpers) directly.

=head2 Public Methods

=head3 new

new() constructs a new Reflex::POE::Postback object, which will be a
blessed coderef following POE's postback convention.

It takes three positional parameters: the required object and method
to invoke when the postback is called, and an optional context that
will be passed verbatim to the callback.

=head2 Callback Parameters

=head3 context

The "context" callback parameter contains whatever was supplied to the
Reflex::POE::Postback when it was created.  In the case of the
SYNOPSIS, that would be:

	sub on_component_result {
		my ($self, $arg) = @_;

		# Displays: 123
		print $arg->{context}{cookie}, "\n";
	}

=head3 response

"response" contains an array reference that holds whatever was passed
to the postback.  If we assume this postback call:

	$postback->(qw(eight six seven five three oh nine));

Then the callback might look something like this:

	sub on_component_result {
		my ($self, $arg) = @_;

		# Displays: nine
		print "$arg->{response}[-1]\n";
	}

=head1 CAVEATS

Reflex::POE::Postback must produce objects as blessed coderefs.  This
is something I don't know how to do yet with Moose, so Moose isn't
used.  Therefore, Reflex::POE::Postback doesn't do a lot of things one
might expect after working with other Reflex objects.

If Moose can be used later, it may fundamentally change the entire
interface.  The goal is to do this only once, however.

It might be nice to map positional response parameters to named
parameters.  Reflex::POE::Wheel does this, but it remains to be seen
whether that's considered cumbersome.

=head1 SEE ALSO

L<Moose::Manual::Concepts>

L<Reflex>
L<Reflex::POE::Event>
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
