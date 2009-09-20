package Reflex::Trait::Observer;
use Moose::Role;
use Scalar::Util qw(weaken);

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

			$self->observe_role(
				observed  => $value,
				role      => (
					$role ||=
					$self->meta->find_attribute_by_name($meta_self->name())->role()
				),
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
				$self->observe_role(
					observed => $value,
					role     => (
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
	isa     => 'CodeRef',
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
