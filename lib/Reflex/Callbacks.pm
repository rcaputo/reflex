package Reflex::Callbacks;
# vim: ts=2 sw=2 noexpandtab

# Reflex::Callbacks is a callback manager.  It encapsulates the
# callbacks for an object.  Via deliver(), it maps event names to the
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
	],
	with_caller => [
		qw(
			make_emitter
			make_terminal_emitter
			make_error_handler
			make_null_handler
		)
	],
);

use Carp qw(croak);

has callback_map => (
	is      => 'rw',
	isa     => 'HashRef[Reflex::Callback]',
	default => sub { {} },
);

coerce 'Reflex::Callback'
	=> from 'CodeRef'
		=> via { die; Reflex::Callback::CodeRef->new( code_ref => $_ ) };

coerce 'Reflex::Callback'
	=> from 'Str'
		=> via {
			die;
			Reflex::Callback::Method->new(
				method_name => $_,
			)
		};

coerce 'Reflex::Callback'
	=> from 'ArrayRef'
		=> via {
			die;
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
	return("on_$methods" => cb_method($object, $methods)) unless ref $methods;

	# Events match method names.
	return( map { ("on_$_" => cb_method($object, $_)) } @$methods ) if (
		ref($methods) eq "ARRAY"
	);

	return (
		map { ("on_$_" => cb_method($object, $methods->{$_})) }
		keys %$methods
	) if ref($methods) eq "HASH";

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
		map { /$method_prefix/; $1 }
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
	my ($owner, $arg, $match) = @_;
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
				$callback->object($owner) unless $callback->object();
				$return{$_} = $callback;
				next;
			}

			die "blessed callback $_";
		}

		# Unblessed callback types must be coerced.

		if (ref($callback) eq "CODE") {
			$return{$_} = Reflex::Callback::CodeRef->new(
				object    => $owner,
				code_ref  => $callback,
			);
			next;
		}

		die "unblessed callback $_";
	}

	return Reflex::Callbacks->new( callback_map => \%return );
}

sub deliver {
	my ($self, $event, $arg) = @_;
	$arg ||= {};

	$event =~ s/^(on_)?/on_/;

	$self->callback_map()->{$event}->deliver($event, $arg);
}

sub make_emitter {
	my $caller = shift();

	my $meta = Class::MOP::class_of($caller);

	my ($method_name, $event_name) = @_;

	my $method = $meta->method_metaclass->wrap(
		package_name => $caller,
		name         => $method_name,
		body         => sub {
			my ($self, $args) = @_;
			$self->emit(event => $event_name, args => $args);
		},
	);

	$meta->add_method($method_name => $method);

	return $method_name;
}

sub make_terminal_emitter {
	my $caller = shift();

	my $meta = Class::MOP::class_of($caller);

	my ($method_name, $event_name) = @_;

	my $method = $meta->method_metaclass->wrap(
		package_name => $caller,
		name         => $method_name,
		body         => sub {
			my ($self, $args) = @_;
			$self->emit(event => $event_name, args => $args);
			$self->stopped();
		},
	);

	$meta->add_method($method_name => $method);

	return $method_name;
}

sub make_error_handler {
	my $caller = shift();

	my $meta = Class::MOP::class_of($caller);

	my ($method_name, $event_name) = @_;

	my $method = $meta->method_metaclass->wrap(
		package_name => $caller,
		name         => $method_name,
		body         => sub {
			my ($self, $args) = @_;
			warn "$args->{errfun} error $args->{errnum}: $args->{errstr}\n";
			$self->stopped();
		},
	);

	$meta->add_method($method_name => $method);

	return $method_name;
}

sub make_null_handler {
	my $caller = shift();

	my $meta = Class::MOP::class_of($caller);

	my ($method_name, $event_name) = @_;

	my $method = $meta->method_metaclass->wrap(
		package_name => $caller,
		name         => $method_name,
		body         => sub { undef },
	);

	$meta->add_method($method_name => $method);

	return $method_name;
}

1;

__END__

=head1 NAME

Reflex::Callbacks - Convenience functions for creating and using callbacks

=head1 SYNOPSIS

This package contains several helper functions, each with its own use
case.  Please see individual examples.

=head1 DESCRIPTION

Reflex::Callback and its subclasses implement the different types of
calbacks that Reflex supports.  Reflex::Callbacks provides convenience
functions that are almost always used instead of Reflex::Callback
objects.

Reflex::Callback's generic interface is a constructor and a single
method, deliver(), which routes its parameters to their destination.
Subclasses may implement additional methods to support specific use
cases.

=head2 cb_method

Creates and returns Reflex::Callback::Method object.  Accepts two
positional parameters: the object reference and method name to invoke
when the callback is delivered.

Relex::Callback::Method's SYNOPSIS has an example, as does the eg
directory in Reflex's distribution.

=head2 cb_object

cb_object() converts the specification of multiple callbacks into a
list of callback parameter names and their Reflex::Callback::Method
objects.  The returned list is in a form suitable for a Reflex::Base
constructor.

cb_object() takes two positional parameters.  The first is the object
reference that will handle callbacks.  The second describes the events
and methods that will handle them.  It may be a scalar string, an
array reference, or a hash reference.

If the second parameter is a scalar string, then a single method will
handle a single event.  The event and method names will be identical.
cb_object() will then return two values: the event name, and the
Reflex::Callback::Method to invoke the corresponding object method.

	use Reflex::Callbacks qw(cb_object);
	my $object = bless {};
	my @cbs = cb_object($object, "event");

	# ... is equivalent to:

	use Reflex::Callback::Method;
	my $object = bless {};
	my @cbs = (
		on_event => Reflex::Callback::Method->new(
			object => $object, method_name => "event"
		)
	);

If the second parameter is an array reference of event names, then one
Reflex::Callback::Method will be created for each event.  The event
names and method names will be identical.

	use Reflex::Callbacks qw(cb_object);
	my $object = bless {};
	my @cbs = cb_object($object, ["event_one", "event_two"]);

	# ... is equivalent to:

	use Reflex::Callback::Method;
	my $object = bless {};
	my @cbs = (
		on_event_one => Reflex::Callback::Method->new(
			object => $object, method_name => "event_one"
		),
		on_event_two => Reflex::Callback::Method->new(
			object => $object, method_name => "event_two"
		),
	);

If the second parameter is a hash reference, then it should be keyed
on event name.  The corresponding values should be method names.  This
syntax allows event and method names to differ.

	use Reflex::Callbacks qw(cb_object);
	my $object = bless {};
	my @cbs = cb_object($object, { event_one => "method_one" });

	# ... is equivalent to:

	use Reflex::Callback::Method;
	my $object = bless {};
	my @cbs = (
		on_event_one => Reflex::Callback::Method->new(
			object => $object, method_name => "method_one"
		)
	);

=head2 cb_class

cb_class() is an alias for cb_object().  Perl object and class methods
currently behave the same, so there is no need for additional code at
this time.

=head2 cb_role

cb_role() implements Reflex's role-based callbacks.  These callbacks
rely on method names to contain clues about the objects and events
being handled.  For instance, a method named on_resolver_answer()
hints that it handles the "answer" events from a sub-object with the
role of "resolver".

cb_role() requires two parameters and has a third optional one.  The
first two parameters are the callback object reference and the role of
the object for which it handles events.  The third optional parameter
overrides the "on" prefix with a different one.

	{
		package Handler;
		sub on_resolver_answer { ... }
		sub on_resolver_failure { ... }
	}

	# This role-based definition:

	use Reflex::Callbacks qw(cb_role);
	my $object = Handler->new();
	my @cbs = cb_role($object, "resolver");

	# ... is equivalent to:

	use Reflex::Callbacks qw(cb_object);
	my $object = Handler->new();
	my @cbs = cb_object(
		$object, {
			answer  => "on_resolver_answer",
			failure => "on_resolver_failure",
		}
	);

	# ... or:

	use Reflex::Callbacks qw(cb_method);
	my $object = Handler->new();
	my @cbs = (
		on_answer => Reflex::Callback::Method->new(
			object => $object, method_name => "on_resolver_answer"
		),
		on_failure => Reflex::Callback::Method->new(
			object => $object, method_name => "on_resolver_failure"
		),
	);

=head2 cb_promise

cb_promise() takes a scalar reference.  This reference will be
populated with a Reflex::Callback::Promise object.

cb_promise() returns two values that are suitable to insert onto a
Reflex::Base's constructor.  The first value is a special event name,
"on_promise", that tells Reflex::Base objects they may be used inline
as promises.  The second return value is the same
Reflex::Callback::Promise object that was inserted into cb_promise()'s
parameter.

	use Reflex::Callbacks qw(cb_promise);
	my $promise;
	my @cbs = cb_promise(\$promise);

	# ... is eqivalent to:

	use Reflex::Callback::Promise;
	my $promise = Reflex::Callback::Promise->new();
	@cbs = ( on_promise => $promise );

=head2 cb_coderef

cb_coderef() takes a single parameter, a coderef to callback.  It
returns a single value: a Reflex::Callback::Coderef object that will
deliver events to the callback.

cb_coderef() neither takes nor returns an event name.  As such, the
Reflex::Base parameter name must be supplied outside cb_coderef().

	my $timer = Reflex::Interval->new(
		interval    => 1,
		auto_repeat => 1,
		on_tick     => cb_coderef { print "tick!\n" },
	);

As shown above, cb_coderef() is prototyped to make the callback's
C<sub> declaration optional.

=head1 Usages Outside Reflex

Reflex callbacks are designed to be independent of any form of
concurrency.  Reflex::Callbacks provides two convenience functions
that other class libraries may find useful but Reflex doesn't use.

Please contact the authors if there's interest in using these
functions, otherwise they may be deprecated.

=head2 gather_cb

The gather_cb() function extracts callbacks from an object's
constructor parameters and encapsulates them in a Reflex::Callbacks
object.

gather_cb() takes three parameters: The object that will own the
callbacks, a hash reference containing a constructor's named
parameters, and an optional regular expression to match callback
parameter names.  By default, gather_cb() will collect
parameters matching C</^on_/>.

	package ThingWithCallbacks;
	use Moose;

	use Reflex::Callbacks qw(gather_cb);

	has cb => ( is => 'rw', isa => 'Reflex::Callbacks' );

	sub BUILD {
		my ($self, $arg) = @_;
		$self->cb(gather_cb($self, $arg));
	}

	sub run {
		my $self = shift;
		$self->cb()->deliver( event => {} );
	}

=head1 deliver

deliver() is a method of Reflex::Callback, not a function.  It takes
two parameters: the name of an event to deliver, and a hash reference
containing named values to include with the event.

deliver() finds the callback that corresponds to its event.  It then
delivers the event to that callback.  The callback must have been
collected by gather_cb().

See the example for gather_cb(), which also invokes deliver().

=head1 SEE ALSO

L<Reflex>
L<Reflex::Callback::CodeRef>
L<Reflex::Callback::Method>
L<Reflex::Callback::Promise>
L<Reflex::Callbacks> documents callback convenience functions.

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
