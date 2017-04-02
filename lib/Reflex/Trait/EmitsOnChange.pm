package Reflex::Trait::EmitsOnChange;

# vim: ts=2 sw=2 noexpandtab

use Moose::Role;
use Scalar::Util qw(weaken);

use Moose::Exporter;
Moose::Exporter->setup_import_methods( with_caller => [ qw( emits ) ]);

use Reflex::Event::ValueChange;

has setup => (
	isa     => 'CodeRef|HashRef',
	is      => 'ro',
);

has trigger => (
	is => 'ro',
	default => sub {
		my $meta_self = shift;

		# $meta_self->name() is not set yet.
		# Weaken $meta_self so that the closure isn't permanent.

		my $event;
		my $old_value;

		sub {
			my ($self, $new_value) = @_;

			# Edge-detection.  Only emit when a value has changed.
			# TODO - Make this logic optional.  Sometimes an application
			# needs level logic rather than edge logic.

			#return if (
			#	(!defined($value) and !defined($last_value))
			#		or
			#	(defined($value) and defined($last_value) and $value eq $last_value)
			#);

			$self->emit(
				-type => 'Reflex::Event::ValueChange',
				-name => (
					$event ||=
					$self->meta->find_attribute_by_name($meta_self->name())->event()
				),
				old_value => $old_value,
				new_value => $new_value,
			);

			$old_value = $new_value;
			weaken $old_value if defined($old_value) and ref($old_value);
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
				-name => (
					$event ||=
					$self->meta->find_attribute_by_name($attr->name())->event()
				),
				value => $value,
			);

			$callback->($value);
		}
	},
);

has event => (
	isa     => 'Str',
	is      => 'ro',
	lazy    => 1,
	default => sub {
		my $self = shift;
		return $self->name();
	},
);

### EmitsOnChanged declarative syntax.

sub emits {
	my ($caller, $name, %etc) = @_;
	my $meta = Class::MOP::class_of($caller);
	push @{$etc{traits}}, __PACKAGE__;
	$etc{is} = 'rw' unless exists $etc{is};
	$meta->add_attribute($name, %etc);
}

package Moose::Meta::Attribute::Custom::Trait::Reflex::Trait::EmitsOnChange;

sub register_implementation { 'Reflex::Trait::EmitsOnChange' }

1;

__END__

=for Pod::Coverage emits

=head1 NAME

Reflex::Trait::EmitsOnChange - Emit an event when an attribute's value changes.

=head1 SYNOPSIS

	# Not a complete program.  See examples eg-09-emitter-trait.pl
	# and eg-10-setup.pl for working examples.

	package Counter;
	use Moose;
	extends 'Reflex::Base';
	use Reflex::Trait::EmitsOnChange;

	emits count => (
		isa       => 'Int',
		default   => 0,
	);

An equivalent alternative:

	has count   => (
		traits    => ['Reflex::Trait::EmitsOnChange'],
		isa       => 'Int',
		is        => 'rw',
		default   => 0,
	);

=head1 DESCRIPTION

An attribute with the Reflex::Trait::EmitsOnChange trait emit an event
on behalf of its object whenever its value changes.  The event will be
named after the attribute by default.  It will be accompanied by a
"value" parameter, the value of which is the attribute's new value at
the time of the change.

In the SYNOPSIS example, changes to count() cause its Counter object
to emit "count" events.

=head2 event

The "default" option can be used to override the default event emitted
by the Reflex::Trait::EmitsOnChange trait.  That default, by the way,
is the name of the attribute.

=head2 setup

The "setup" option provides default constructor parameters for the
attribute.  In the above example, clock() will by default contain

	Reflex::Interval->new(interval => 1, auto_repeat => 1);

In other words, it will emit the Reflex::Interval event ("tick") once
per second until destroyed.

=head1 Declarative Syntax

Reflex::Trait::EmitsOnChange exports a declarative emits() function,
which acts almost identically to Moose's has() but with a couple
convenient defaults: The EmitsOnChange trait is added, and the
attribute is "rw" to allow changes.

=head1 CAVEATS

The "setup" option is a work-around for unfortunate default timing.
It will be deprecated if default can be made to work instead.

=head1 SEE ALSO

L<Reflex>
L<Reflex::Trait::Watches>

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
