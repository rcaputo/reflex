package ObserverTrait;
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

		sub {
			my ($self, $value) = @_;

			# TODO - Ignore the object when we're set to undef.  Probably
			# part of a clearer method.  Currently we rely on the object
			# destructing on clear, which also triggers ignore().

			return unless defined $value;

			$self->observe_role(
				observed  => $value,
				role      => $self->meta->get_attribute($meta_self->name())->role(),
			);
		}
	}
);

has role => (
	isa     => 'Str',
	is      => 'ro',
	default => sub {
		my $self = shift;
		return $self->name();
	},
);

package Moose::Meta::Attribute::Custom::Trait::Observer;
sub register_implementation { 'ObserverTrait' }

1;
