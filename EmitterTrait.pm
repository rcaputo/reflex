package EmitterTrait;
use Moose::Role;
use Scalar::Util qw(weaken);

has trigger => (
	is => 'ro',
	default => sub {
		my $meta_self = shift;

		# $meta_self->name() is not set yet.
		# Weaken $meta_self so that the closure isn't fatal.
		weaken $meta_self;

		sub {
			my ($self, $value) = @_;

			$self->emit(
				args => {
					value => $value,
				},
				event => $self->meta->get_attribute($meta_self->name())->event(),
			);
		}
	}
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

package Moose::Meta::Attribute::Custom::Trait::Emitter;
sub register_implementation { 'EmitterTrait' }

1;
