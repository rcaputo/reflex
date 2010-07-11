package Reflex::Role;
use Moose::Role;
use MooseX::Role::Parameterized;
use Moose::Exporter;

# TODO - All role-based method definition goes through here, as do
# callback parameters.  We have an opportunity to validate that
# the defined callbacks and methods are sane, if Moose doesn't already
# do this for us!

Moose::Exporter->setup_import_methods(
	with_caller => [ qw(
		attribute_parameter method_parameter callback_parameter
		method_emit_and_stop method_emit
	) ],
	also => 'MooseX::Role::Parameterized',
);

sub attribute_parameter {
	my $caller = shift;

	confess "'attribute_parameter' may not be used inside of the role block"
	if (
		MooseX::Role::Parameterized::current_metaclass() and
		MooseX::Role::Parameterized::current_metaclass()->genitor->name eq $caller
	);

	my $meta = Class::MOP::class_of($caller);

	my ($name, $default) = @_;

	$meta->add_parameter($name, ( isa => 'Str', default => $default ) );
}

sub method_parameter {
	my $caller = shift;

	confess "'method_parameter' may not be used inside of the role block"
	if (
		MooseX::Role::Parameterized::current_metaclass() and
		MooseX::Role::Parameterized::current_metaclass()->genitor->name eq $caller
	);

	my $meta = Class::MOP::class_of($caller);

	my ($name, $prefix, $member, $suffix) = @_;

	# TODO - $member must have been declared as an attribute_parameter.

	$meta->add_parameter(
		$name,
		(
			isa     => 'Str',
			lazy    => 1,
			default => sub {
				join(
					"_",
					grep { defined() and $_ ne "_" }
					$prefix, shift()->$member(), $suffix
				)
			},
		)
	);
}

sub method_emit_and_stop {
    my $caller = shift;
    my $meta   = (
			MooseX::Role::Parameterized::current_metaclass() ||
			Class::MOP::class_of($caller)
		);

		my ($method_name, $event_name) = @_;

    my $method = $meta->method_metaclass->wrap(
        package_name => $caller,
        name         => $method_name,
        body         => sub {
					my ($self, $args) = @_;
					$self->emit(event => $event_name, args => $args);
					$self->stopped();
				},
    );

    $meta->add_method($method_name => $method);
}

sub method_emit {
    my $caller = shift;
    my $meta   = (
			MooseX::Role::Parameterized::current_metaclass() ||
			Class::MOP::class_of($caller)
		);

		my ($method_name, $event_name) = @_;

    my $method = $meta->method_metaclass->wrap(
        package_name => $caller,
        name         => $method_name,
        body         => sub {
					my ($self, $args) = @_;
					$self->emit(event => $event_name, args => $args);
				},
    );

    $meta->add_method($method_name => $method);
}

# Aliased here.
# TODO - Find out how Moose::Exporter might export method_parameter()
# as both names.
#
# TODO - Default emit methods (method_emit and method_emit_and_stop)
# are common for callback parameters.  We could include callback
# parameter flags to automatically generate those methods.
BEGIN { *callback_parameter = *method_parameter; }

1;
