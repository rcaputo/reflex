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

__END__

=head1 NAME

Reflex::Trait::Emitter - Automatically emit events when values change.

=head1 SYNOPSIS

# Not a complete program.  See examples eg-09-emitter-trait.pl and
# eg-10-setup.pl for working examples.

	{
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
	}

=head1 DESCRIPTION

Reflex::Trait::Emitter allows an object to automatically emit an event
when the value of its attribute changes.  In the SYNOPSIS, changing
the value of count() will cause the Counter object to emit a "count"
event with the new count's value.

Custom mutators may also use Reflex::Object's emit() method to
announce changes.  Reflex::Trait::Emitter is expected to handle many
common scenarios.

TODO - Complete the documentation.

=head1 GETTING HELP

L<Reflex/GETTING HELP>

=head1 ACKNOWLEDGEMENTS

L<Reflex/ACKNOWLEDGEMENTS>

=head1 SEE ALSO

L<Reflex> and L<Reflex/SEE ALSO>

=head1 BUGS

L<Reflex/BUGS>

=head1 CORE AUTHORS

L<Reflex/CORE AUTHORS>

=head1 OTHER CONTRIBUTORS

L<Reflex/OTHER CONTRIBUTORS>

=head1 COPYRIGHT AND LICENSE

L<Reflex/COPYRIGHT AND LICENSE>

=cut
