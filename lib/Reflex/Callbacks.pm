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
use Reflex::Callback::CodeRef;
#use Reflex::Callback::Emit;   # For current Reflex compatibility
use Reflex::Callback::Method;
use Reflex::Callback::Promise;

use Moose::Exporter;
Moose::Exporter->setup_import_methods(
	as_is => [
		qw(
			cb_class
			cb_coderef
			cb_method
			cb_object
			cb_promise
			cb_role
			gather_cb
		)
	]
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
	my ($object, $method_name) = @_;
	return Reflex::Callback::Method->new(
		object      => $object,
		method_name => $method_name,
	);
}

sub cb_object {
	my ($object, $methods) = @_;

	# They passed us a scalar.  Emulate cb_methods().
	return ($methods => cb_method(@_)) unless ref $methods;

	if (ref($methods) eq "ARRAY") {
		return map { ($_ => cb_method($object, $_)) } @$methods;
	}

	if (ref($methods) eq "HASH") {
		return(
			map { ($_ => cb_method($object, $methods->{$_})) }
			keys %$methods
		);
	}

	croak "cb_object with unknown methods type: $methods";
}

# A bit of a cheat.  Goes with the Object|Str type constraint in
# Reflex::Callback::Method.
sub cb_class {
	cb_object(@_);
}

# Role callbacks inspect the handler object or class methods and
# determine the events being handled by their names.
sub cb_role {
	my ($invocant, $role, $prefix) = @_;
	$prefix = "on" unless defined $prefix;

	my $method_prefix = qr/^${prefix}_${role}_(\S+)/;

	my @class_methods = (
		grep /$method_prefix/,
		map { $_->name() }
		$invocant->meta()->get_all_methods()
	);

	my @events = (
		map { /$method_prefix/; "on_$1" }
		@class_methods
	);

	my %methods;
	@methods{@events} = @class_methods;

	return cb_object($invocant, \%methods);
}

sub cb_promise {
	my $promise_ref = shift;

	$$promise_ref = Reflex::Callback::Promise->new();

	return( on_promise => $$promise_ref );
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
			if ($callback->isa('Reflex::Callback::Promise')) {
				return $callback;
			}

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

	$event =~ s/^(on_)?/on_/;

	$self->callback_map()->{$event}->deliver($event, $arg);
}

sub add_callback {
	my ($self, %callback_map) = @_;
	while (my ($event, $callback) = each %callback_map) {
		$self->callback_map()->{$event} = $callback;
	}
}

1;
