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

has setup => (
	isa     => 'CodeRef|HashRef',
	is      => 'ro',
);

package Moose::Meta::Attribute::Custom::Trait::Reflex::Trait::Emitter;
sub register_implementation { 'Reflex::Trait::Emitter' }

1;
