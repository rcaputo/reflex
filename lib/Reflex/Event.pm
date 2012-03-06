package Reflex::Event;

use Moose;
use Scalar::Util qw(weaken);

has _name => (
	is      => 'ro',
	isa     => 'Str',
	default => 'generic',
);

has _emitters => (
	is       => 'ro',
	isa      => 'ArrayRef[Any]',
	traits   => ['Array'],
	required => 1,
	handles  => {
		get_first_emitter => [ 'get', 0  ],
		get_last_emitter  => [ 'get', -1 ],
		get_all_emitters  => 'elements',
	}
);

sub BUILD {
	my $self = shift();

	# After build, weaken any emitters passed in.
	#my $emitters = $self->_emitters();
	#weaken($_) foreach @$emitters;
}

sub push_emitter {
	my ($self, $item) = @_;

	use Carp qw(confess); confess "wtf" unless defined $item;

	my $emitters = $self->_emitters();
	push @$emitters, $item;
	#weaken($emitters->[-1]);
}

sub _headers {
	my $self = shift();
	return (
		map  { "-" . substr($_,1), $self->$_() }
		grep { /^_/            }
		map  { $_->name()      }
		Class::MOP::Class->initialize(ref($self))->get_all_attributes()
	);
}

sub _body {
	my $self = shift();
	return (
		map  { $_, $self->$_() }
		grep { !/^_/           }
		map  { $_->name()      }
		Class::MOP::Class->initialize(ref($self))->get_all_attributes()
	);
}

sub _clone {
	my ($self, %override_args) = @_;

	my %clone_args;

	my @attribute_names = (
		map { $_->name() }
		Class::MOP::Class->initialize(ref($self))->get_all_attributes()
	);

	@clone_args{@attribute_names} = map { $self->$_() } @attribute_names;

	my @override_keys = keys %override_args;
	@clone_args{ map { s/^-/_/; $_ } @override_keys } = values %override_args;

	my $new_type = delete($clone_args{_type}) || ref($self);
	my $emitters = delete($clone_args{_emitters}) || confess "no -emitters";

	my $new_event = $new_type->new(%clone_args, _emitters => [ @$emitters ]);

	return $new_event;
}

# Override Moose's dump().
sub dump {
	my $self = shift;

	my $dump = "=== $self ===\n";
	my %clone = ($self->_headers(), $self->_body());
	foreach my $k (sort keys %clone) {
		$dump .= "$k: $clone{$k}\n";
		if ($k eq '-emitters') {
			my @emitters = $self->get_all_emitters();
			for my $i (0..$#emitters) {
				$dump .= "    emitter $i: $emitters[$i]\n";
			}
		}
	}

	# No newline so we get line numbers.
	$dump .= "===";

	return $dump;
}

1;
