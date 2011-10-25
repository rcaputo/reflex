package Reflex::Callback::Method;
# vim: ts=2 sw=2 noexpandtab

use Moose;
extends 'Reflex::Callback';

has method_name => (
	is        => 'ro',
	isa       => 'Str',
	required  => 1,
);

sub deliver {
	my ($self, $event) = @_;
	my $method_name = $self->method_name();
	$self->object()->$method_name($event);
}

1;

__END__

=head1 NAME

Reflex::Callback::Method - Callback adapter for class and object methods

=head1 SYNOPSIS

Used within Reflex:

	package MethodHandler;
	use Moose;
	extends 'Reflex::Base';
	use Reflex::Callbacks qw(cb_method);
	use ExampleHelpers qw(eg_say);

	has ticker => (
		isa     => 'Maybe[Reflex::Interval]',
		is      => 'rw',
	);

	sub BUILD {
		my $self = shift;
		$self->ticker(
			Reflex::Interval->new(
				interval    => 1 + rand(),
				auto_repeat => 1,
				on_tick     => cb_method($self, "callback"),
			)
		);
	}

	sub callback {
		eg_say("method callback triggered");
	}

	MethodHandler->new()->run_all();

Low-level usage:

	{
		package Object;
		use Moose;

		sub callback {
			my ($self, $arg) = @_;
			print "$self says: hello, $arg->{name}\n";
		}
	}

	my $object = Object->new();

	my $cb = Reflex::Callback::Method->new(
		object      => $object,
		method_name => "callback"
	);

	$cb->deliver(greet => { name => "world" });

=head1 DESCRIPTION

Reflex::Callback::Method maps the generic Reflex::Callback interface
to object and class method callbacks.  Reflex::Callbacks' cb_method()
function simplifies callback creation.  cb_object(), also supplied by
Reflex::Callbacks, is shorthand for setting several callbacks at once
on a single object or class.  Other syntactic sweeteners are in
development.

=head2 new

Reflex::Callback::Method's constructor takes two named parameters.
"object" and "method_name" define the object and method that will be
invoked to handle the callback.

Despite its name, "object" may also handle class names.  In these
cases, "method_name" will be invoked as a class method rather than on
a particular instance of the class.

=head2 deliver

Reflex::Callback::Method's deliver() method invokes the object (or
class) and method as defined during the callback's construction.
deliver() takes two positional parameters: an event name (which is not
currently used for method callbacks), and a hashref of named
parameters to be passed to the callback.

deliver() returns whatever the coderef does.

=head1 SEE ALSO

L<Reflex>
L<Reflex::Callback>
L<Reflex::Callbacks>

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
