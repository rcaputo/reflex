package Reflex::Trait::Emitter;
use Moose::Role;
use Scalar::Util qw(weaken);

has trigger => (
	is => 'ro',
	default => sub {
		my $meta_self = shift;

		# $meta_self->name() is not set yet.
		# Weaken $meta_self so that the closure isn't permanent.

		my $event;
		#my $last_value;

		sub {
			my ($self, $value) = @_;

			# Edge-detection.  Only emit when a value has changed.
			# TODO - Make this logic optional.  Sometimes an application
			# needs level logic rather than edge logic.

			#return if (
			#	(!defined($value) and !defined($last_value))
			#		or
			#	(defined($value) and defined($last_value) and $value eq $last_value)
			#);
			#
			#$last_value = $value;
			#weaken $last_value if defined($last_value) and ref($last_value);

			$self->emit(
				args => {
					value => $value,
				},
				event => (
					$event ||=
					$self->meta->find_attribute_by_name($meta_self->name())->event()
				),
			);
		}
	}
);

has initializer => (
	is => 'ro',
	default => sub {
		my $role;
		return sub {
			my ($self, $value, $callback, $attr) = @_;
			my $event;
			$self->emit(
				args => {
					value => $value,
				},
				event => (
					$event ||=
					$self->meta->find_attribute_by_name($attr->name())->event()
				),
			);

			$callback->($value);
		}
	},
);

has event => (
	isa     => 'Str',
	is      => 'ro',
	default => sub {
		my $self = shift;
		return $self->name();
	},
);

package Moose::Meta::Attribute::Custom::Trait::Reflex::Trait::Emitter;
sub register_implementation { 'Reflex::Trait::Emitter' }

1;

__END__

=head1 NAME

Reflex::Trait::Emitter - Emit an event when an attribute's value changes.

=head1 SYNOPSIS

	# Not a complete program.  See examples eg-09-emitter-trait.pl
	# and eg-10-setup.pl for working examples.

	package Counter;
	use Moose;
	extends 'Reflex::Object';
	use Reflex::Trait::Emitter;

	has count   => (
		traits    => ['Reflex::Trait::Emitter'],
		isa       => 'Int',
		is        => 'rw',
		default   => 0,
	);

=head1 DESCRIPTION

An attribute with the Reflex::Trait::Emitter trait emit an event on
behalf of its object whenever its value changes.  The event will be
named after the attribute by default.  It will be accompanied by a
"value" parameter, the value of which is the attribute's new value at
the time of the change.

In the SYNOPSIS example, changes to count() cause its Counter object
to emit "count" events.

=head2 event

The "default" option can be used to override the default event emitted
by the Reflex::Trait::Emitter trait.  That default, by the way, is the
name of the attribute.

=head1 SEE ALSO

L<Reflex>
L<Reflex::Trait::Observer>

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
