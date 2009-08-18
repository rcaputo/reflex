package ObserverTrait;
use Moose::Role;

has trigger => (
	is => 'ro',
	default => sub {
		sub {
			my ($self, $value) = @_;

			# TODO - Ignore the object when we're set to undef.  Probably
			# part of a clearer method.  Currently we rely on the object
			# destructing on clear, which also triggers ignore().

			return unless defined $value;
			$self->observe_role(
				observed  => $value,
				role      => $self->meta->get_attribute('child')->role(),
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
