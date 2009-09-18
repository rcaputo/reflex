package Postback;

# TODO - Not Moose, unless Moose allows us to create blessed coderefs.

use warnings;
use strict;
use Scalar::Util qw(weaken);

my %owner_session_ids;

sub new {
	my ($class, $object, $method, $passthrough_args) = @_;

	# TODO - Object owns component, which owns object?
	weaken $object;

	my $self = bless sub {
		$POE::Kernel::poe_kernel->post(
			$object->session_id(), "call_gate_method", $object, $method, {
				passthrough => $passthrough_args,
				callback => [ @_ ],
			},
		);
	}, $class;

	$owner_session_ids{$self} = $object->session_id();
	$POE::Kernel::poe_kernel->refcount_increment(
		$object->session_id(), "stage_postback"
	);

	# Double indirection sucks, but some libraries (like Tk) bless their
	# callbacks.  If we returned our own blessed callback, they would
	# alter the class and thwart DESTROY.
	#
	# TODO - POE::Session only does this when Tk is loaded.  I opted
	# against it because the set of libraries that bless their callbacks
	# may grow over time.

	return sub { $self->(@_) };
}

sub DESTROY {
	my $self = shift;

	my $session_id = delete $owner_session_ids{$self};
	return unless defined $session_id;
	$POE::Kernel::poe_kernel->refcount_decrement(
		$session_id, "stage_postback"
	);

	undef;
}

1;
