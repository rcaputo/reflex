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

	# Get the Stage object that owns this wheel.

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

no Moose;
__PACKAGE__->meta()->make_immutable();

1;
