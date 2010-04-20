package Reflex::Trait::Observer;
use Moose::Role;
use Scalar::Util qw(weaken);
use Reflex::Callbacks qw(cb_role);

has trigger => (
	is => 'ro',
	default => sub {
		my $meta_self = shift;

		# $meta_self->name() is not set yet.
		# Weaken $meta_self so that the closure isn't fatal.
		# TODO - If we can get the name out here, then we save a name()
		# method call every trigger.
		weaken $meta_self;
		my $role;

		sub {
			my ($self, $value) = @_;

			# TODO - Ignore the object when we're set to undef.  Probably
			# part of a clearer method.  Currently we rely on the object
			# destructing on clear, which also triggers ignore().

			return unless defined $value;

			$self->observe(
				$value,
				cb_role(
					$self,
					$role ||=
					$self->meta->find_attribute_by_name($meta_self->name())->role()
				)
			);
		}
	}
);

# Initializer seems to catch the observation from default.  Nifty!

has initializer => (
	is => 'ro',
	default => sub {
		my $role;
		return sub {
			my ($self, $value, $callback, $attr) = @_;
			if (defined $value) {
				$self->observe(
					$value,
					cb_role(
						$self,
						$role ||=
						$self->meta->find_attribute_by_name($attr->name())->role()
					),
				);
			}
			else {
				# TODO - Ignore the object in the old value, if defined.
			}

			$callback->($value);
		}
	},
);

has role => (
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

# TODO - Clearers don't invoke triggers, because clearing is different
# from setting.  I would love to support $self->clear_thingy() with
# the side-effect of unobserving the object, but I don't yet know how
# to set an "after" method for a clearer that (a) has a dynamic name,
# and (b) hasn't yet been defined.  I think I can do some meta magic
# for (a), but (b) remains tough.

#has clearer => (
#	isa     => 'Str',
#	is      => 'ro',
#	default => sub {
#		my $self = shift;
#		return "clear_" . $self->name();
#	},
#);

package Moose::Meta::Attribute::Custom::Trait::Reflex::Trait::Observer;
sub register_implementation { 'Reflex::Trait::Observer' }

1;

__END__

=head1 NAME

Reflex::Trait::Observer - Automatically observe Reflex objects.

=head1 SYNOPSIS

# Not a complete program.  This example comes from Reflex's main
# L<synopsis|Reflex/SYNOPSIS>.

	has clock => (
		isa     => 'Reflex::Timer',
		is      => 'rw',
		traits  => [ 'Reflex::Trait::Observer' ],
		setup   => { interval => 1, auto_repeat => 1 },
	);

=head1 DESCRIPTION

Reflex::Trait::Observer allows one Reflex::Object to automatically
observe other another it has stored in an attribute.  In the SYNOPSIS,
storing a Reflex::Timer in the clock() attribute allows the owner to
observe the timer's events.

This trait is a bit of Moose-based syntactic sugar for
Reflex::Object's more explict observe() and observe_role() methods.

=head2 setup

The "setup" option provides default constructor parameters for the
attribute.  In the above example, clock() will by default contain

	Reflex::Timer->new(interval => 1, auto_repeat => 1);

In other words, it will emit the Reflex::Timer event ("tick") once per
second until destroyed.

=head2 role

Attribute events are mapped to the owner's methods using Reflex's
role-based callback convention.  For example, Reflex will look for an
on_clock_tick() method to handle "tick" events from an object with the
'clock" role.

The "role" option allows roles to be set or overridden.  An observer
attribute's name is its default role.

=head1 SEE ALSO

L<Reflex>
L<Reflex::Trait::Emitter>

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
