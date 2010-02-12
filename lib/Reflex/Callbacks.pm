package Reflex::Callbacks;

# Reflex::Callbacks is a callback manager.  It encapsulates the
# callbacks for an object.  Via send(), it maps event names to the
# corresponding callbacks, then invokes them through the underlying
# callback system.
#
# On another level, it makes sure all the callback classes are loaded
# and relevant coercions are defined.
#
# TODO - Explore whether it's sensible for the underlying callback
# system to be pluggable.

use Moose;
use Moose::Util::TypeConstraints;

use Reflex::Callback;
#use Reflex::Callback::Class;
use Reflex::Callback::CodeRef;
#use Reflex::Callback::Emit;   # For current Reflex compatibility
#use Reflex::Callback::Method;
#use Reflex::Callback::Object;
#use Reflex::Callback::Promise;
#use Reflex::Callback::Role;

use Exporter;
use base qw(Exporter);
our @EXPORT_OK = qw(
	cb_class
	cb_coderef
	cb_method
	cb_object
	cb_promise
	cb_role
	gather_cb
);

use Carp qw(croak);

has callback_map => (
	is      => 'rw',
	isa     => 'HashRef[Reflex::Callback]',
	default => sub { {} },
);

coerce 'Reflex::Callback'
	=> from 'CodeRef'
		=> via { Reflex::Callback::CodeRef->new( code_ref => $_ ) };

coerce 'Reflex::Callback'
	=> from 'Str'
		=> via {
			Reflex::Callback::Method->new(
				method_name => $_,
			)
		};

coerce 'Reflex::Callback'
	=> from 'ArrayRef'
		=> via {
			Reflex::Callback::Method->new(
				object => $_->[0],
				method_name => $_->[1],
			)
		};

sub cb_method {
	die;
	my ($object, $method_name) = @_;
	return Reflex::Callback::Method->new(
		object => $object,
		method_name => $method_name,
	);
}

sub cb_object {
	die;
}

sub cb_class {
	die;
}

sub cb_role {
	die;
}

sub cb_promise {
	die;
}

sub cb_coderef (&) {
	return Reflex::Callback::CodeRef->new(code_ref => shift);
}

sub gather_cb {
	my ($arg, $match) = @_;
	$match = qr/^on_/ unless defined $match;

	my %return;

	# TODO - Also analyze whether the value is a Reflex::Callack object.
	foreach (grep /$match/, keys %$arg) {
		die unless defined $arg->{$_};
		my $callback = $arg->{$_};

		if (blessed $callback) {
			if ($callback->isa('Reflex::Callback')) {
				$return{$_} = $callback;
				next;
			}

			die "blessed callback $_";
		}

		# Unblessed callback types must be coerced.

		if (ref($callback) eq "CODE") {
			$return{$_} = Reflex::Callback::CodeRef->new(code_ref => $callback);
			next;
		}

		die "unblessed callback $_";
	}

	return Reflex::Callbacks->new( callback_map => \%return );
}

sub send {
	my ($self, $event, $arg) = @_;
	$arg //= {};
	$self->callback_map()->{$event}->deliver($arg);
}

1;
