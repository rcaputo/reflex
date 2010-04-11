package Reflex::POE::Wheel;
use Moose;
extends 'Reflex::Object';
use Scalar::Util qw(weaken);
use POE::Wheel;

has wheel => (
	isa     => 'Object|Undef',
	is      => 'rw',
);

my %wheel_id_to_object;

sub BUILD {
	my ($self, $args) = @_;

	my $wheel_class = $self->wheel_class();

	# Get rid of stuff we don't need.
	foreach my $param (keys %$args) {
		delete $args->{$param} unless exists $self->valid_params()->{$param};
	}

	# Map methods to events in the wheel parameters.
	my $event_to_index = $self->event_to_index();
	while (my ($wheel_param, $event_idx) = each %$event_to_index) {
		$args->{$wheel_param} = "wheel_event_$event_idx";
	}

	$self->create_wheel($wheel_class, $args);
}

sub create_wheel {
	my ($self, $wheel_class, $args) = @_;

	return unless $self->call_gate("create_wheel", $wheel_class, $args);

	my $wheel = $wheel_class->new( %$args );
	$self->wheel($wheel);

	$wheel_id_to_object{$wheel->ID()} = $self;
	weaken $wheel_id_to_object{$wheel->ID()};
}

sub wheel_id {
	my $self = shift;
	return $self->wheel()->ID();
}

sub DEMOLISH {
	my $self = shift;
	$self->demolish_wheel();
}

sub demolish_wheel {
	my $self = shift;
	return unless defined($self->wheel()) and $self->call_gate("demolish_wheel");
	delete $wheel_id_to_object{ $self->wheel_id() };
	$self->wheel(undef);
}

sub _deliver {
	my ($class, $event_idx, @event_args) = @_;

	# Map parameter offsets to named parameters.
	my $param_names = $class->event_param_names()->[$event_idx];

	my $i = 0;
	my %event_args = map { $_ => $event_args[$i++] } @$param_names;

	# Get the wheel that sent us an event.

	my $wheel_id = $event_args{wheel_id};

	# Get the Reflex::Object that owns this wheel.

	my $self = $wheel_id_to_object{$wheel_id};
	die unless $self;

	# Get the emitted event name associated with this event.
	my $event_name = $self->event_emit_names()->[$event_idx];

	# Emit the event.
	$self->emit(
		event => $event_name,
		args  => \%event_args,
	);
}

1;

__END__

=head1 NAME

Reflex::POE::Wheel - Base class for POE::Wheel wrappers.

=head1 SYNOPSIS

# Not a complete example.  Consider looking at the source for
# Reflex::POE::Wheel::Run, which subclasses Reflex::POE::Wheel.

TODO - Need an example.

=head1 DESCRIPTION

Reflex::POE::Wheel is a base class for POE::Wheel wrappers.
Subclasses will configure Reflex::POE::Wheel to provide the proper
POE::Wheel constructor parameters.  Additional configuration converts
the POE::Wheel events into Reflex::Object events.

Methods are not yet converted automatically.  It seems more sensible
to provide a native Reflex::Object interface, although one could
certainly use Moose's "handles" attribute option to pass the wheel's
methods through the wrapper.

TODO - Complete the documentation.

=head2 wheel_id

Return the internal wheel's ID.

=head2 demolish_wheel

Cause the internal wheel to be demolished.  Provided as a method since
some wheels may require special handling.

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
