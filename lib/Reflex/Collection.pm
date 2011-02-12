# A self-managing collection of objects.  See
# Reflex::Role::Collectible for the other side of the
# Collectible/Collection contract.

package Reflex::Collection;
use Moose;
use Moose::Exporter;
use Reflex::Callbacks qw(cb_method);
use Carp qw(cluck);

# Reflex::Role::Collectible isn't directly used in this module, but
# the role needs to be loaded for the objects() type constraint to
# work below.  Hans Dieter Pearcey recommends the canonical Moose
# practice of declaring types in a separate header-like class:
#
#   package Reflex::Types;
#   use Moose::Util::TypeConstraints;
#   role_type('Reflex::Role::Collectible');
#
# Using Reflex::Types sets up role and type constraints once across
# the entire program.  Problems can occur when the order modules are
# loaded becomes significant.  A Reflex::Types module can avoid them.

use Reflex::Role::Collectible;

extends 'Reflex::Base';

Moose::Exporter->setup_import_methods( with_caller => [ qw( has_many ) ]);

has _objects => (
	is      => 'rw',
	isa     => 'HashRef[Reflex::Role::Collectible]',
	traits  => ['Hash'],
	default => sub { {} },
	handles => {
		_set_object    => 'set',
		_delete_object => 'delete',
		get_objects    => 'values',
	},
);

has _owner => (
	is       => 'ro',
	isa      => 'Object',
	writer   => '_set_owner',
	weak_ref => 1,
);

sub remember {
	my ($self, $object) = @_;

	$self->watch($object, stopped => cb_method($self, "cb_forget"));
	$self->_owner->watch(
		$object,
		result => cb_method($self->_owner, "on_result")
	);

	# TODO - Not iThread safe to use $object as a key.
	$self->_set_object($object, $object);
}

sub forget {
	my ($self, $object) = @_;
	$self->_delete_object($object);
}

sub cb_forget {
	my ($self, $args) = @_;
	$self->_delete_object($args->{_sender}->get_last_emitter());
}

sub has_many {
	my ($caller, $name, %etc) = @_;

	my $meta = Class::MOP::class_of($caller);
	foreach (qw(is isa default)) {
		cluck "has_many is ignoring your '$_' parameter" if exists $etc{$_};
	}

	$etc{is}      = 'ro';
	$etc{isa}     = 'Reflex::Collection';
	$etc{lazy}    = 1 unless exists $etc{lazy};
	$etc{default} = sub {
		my $self = shift;
		return Reflex::Collection->new( _owner => $self );
	};

	$meta->add_attribute($name, %etc);
}

1;

__END__

=head1 NAME

Reflex::Collection - Autmatically manage a collection of collectible objects

=head1 SYNOPSIS

	package TcpEchoServer;

	use Moose;
	extends 'Reflex::Listener';
	use Reflex::Collection;
	use EchoStream;

	# From Reflex::Collection.
	has_many clients => (
		handles => { remember_client => "remember" },
	);

	sub on_listener_accepted {
		my ($self, $args) = @_;
		$self->remember_client(
			EchoStream->new(
				handle => $args->{socket},
				rd     => 1,
			)
		);
	}

    sub broadcast {
        my ($self, $message) = @_;

        foreach my $handle ($self->get_objects) {
            $handle->put($message);
        }
    }

	1;

=head1 DESCRIPTION

Some object manage collections of collectible objects---ones that
consume Reflex::Role::Collectible.  For example, network servers must
track objects that represent client connections.  If not, those
objects would go out of scope, destruct, and disconnect their clients.

Reflex::Collection is a generic object collection manager.  It exposes
remember() and forget(), which may be mapped to other methods using
Moose's "handles" aspect.

Reflex::Collection goes beyond this simple hash-like interface.  It
will automatically forget() objects that emit "stopped" events,
triggering their destruction if nothing else refers to them.  This
eliminates a large amount of repetitive work.

Reflex::Role::Collectible provides a stopped() method that emits the
"stopped" event.  Calling C<<$self->stopped()>> in the collectible
class is sufficient to trigger the proper cleanup.

TODO - Reflex::Collection is an excellent place to manage pools of
objects.  Provide a callback interface for pulling new objects as
needed.

=head2 has_many

Reflex::Collection exports the has_many() function, which works like
Moose's has() with "is", "isa", "lazy" and "default" set to common
values.  For example:

	has_many connections => (
		handles => { remember_connection => "remember" },
	);

... is equivalent to:

	has connections => (
		# Defaults provided by has_many.
		is      => 'ro',
		isa     => 'Reflex::Collection',
		lazy    => 1,
		default => sub { Reflex::Collection->new() {,

		# Customization.
		handles => { remember_connection => "remember" },
	);

=head2 new

Create a new Reflex::Collection.  It takes no parameters.

=head2 remember

Remember an object.  Reflex::Collection works best if it contains the
only references to the objects it manages, so you may often see
objects remembered while they're constructed.  See the SYNOPSIS for
one such example.

remember() takes one parameter: the object to remember.

=head2 forget

Forget an object, returning its reference.  You've supplied the
reference, so the returned one is usually redundant.  forget() takes
one parameter: the object to forget.

=head2 get_objects

Get the collected objects in scope. Returns a list.

=head1 SEE ALSO

L<Reflex>

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
