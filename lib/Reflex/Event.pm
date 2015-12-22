package Reflex::Event;

use Moose;
use Scalar::Util qw(weaken);

# Class scoped storage.
# Each event class has a set of attribute names.
# There's no reason to calculate them every _clone() call.
my %attribute_names;

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

sub _get_attribute_names {
	my $self = shift();
	return(
		$attribute_names{ ref $self } ||= [
			map { $_->name() }
			$self->meta()->get_all_attributes()
		]
	);
}

#sub BUILD {
#	my $self = shift();
#
#	# After build, weaken any emitters passed in.
#	#my $emitters = $self->_emitters();
#	#weaken($_) foreach @$emitters;
#}

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
		grep /^_/,
		@{ $self->_get_attribute_names() },
	);
}

sub _body {
	my $self = shift();
	return (
		map  { $_, $self->$_() }
		grep /^[^_]/,
		@{ $self->_get_attribute_names() },
	);
}

sub make_event_cloner {
	my $class = shift();

	my $class_meta = $class->meta();

	my @fetchers;
	foreach my $attribute_name (
		map { $_->name } $class_meta->get_all_attributes
	) {
		my $override_name = $attribute_name;
		$override_name =~ s/^_/-/;

		next if $attribute_name eq '_emitters';

		push @fetchers, (
			join ' ', (
				"\"$attribute_name\" => (",
				"(exists \$override_args{\"$override_name\"})",
				"? \$override_args{\"$override_name\"}",
				": \$self->$attribute_name()",
				")",
			)
		);
	}

	my $cloner_code = join ' ', (
		'sub {',
		'my ($self, %override_args) = @_;',
		'my %clone_args = ( ',
		join(',', @fetchers),
		');',
		'my $type = $override_args{"-type"} || ref($self);',
		'my $emitters = $self->_emitters() || [];',
		'$type->new(%clone_args, _emitters => [ @$emitters ]);',
		'}'
	);

	my $cloner = eval $cloner_code;
	if ($@) {
		die(
			"cloner compile error: $@\n",
			"cloner: $cloner_code\n"
		);
	}

	$class_meta->add_method( _clone => $cloner );
}

# Override Moose's dump().
sub dump {
	my $self = shift;

	my $dump = "=== $self ===\n";
	my %clone = ($self->_headers(), $self->_body());
	foreach my $k (sort keys %clone) {
		$dump .= "  $k: " . ($clone{$k} // '(undef)') . "\n";
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

__PACKAGE__->make_event_cloner;
__PACKAGE__->meta->make_immutable;

1;

__END__

=for Pod::Coverage make_event_cloner push_emitter
