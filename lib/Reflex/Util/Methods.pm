package Reflex::Util::Methods;

use warnings;
use strict;

use Exporter;
use base 'Exporter';

our @EXPORT_OK = qw(emit_an_event method_name emit_and_stopped);

sub emit_an_event {
	my ($event_name) = @_;
	return sub {
		my ($self, $args) = @_;
		$self->emit(event => $event_name, args => $args);
	};
}

sub emit_and_stopped {
	my ($event_name) = @_;
	return sub {
		my ($self, $args) = @_;
		$self->emit(event => $event_name, args => $args);
		$self->stopped();
	};
}

sub method_name {
	my ($prefix, $member, $suffix) = @_;
	return(
		isa     => 'Str',
		lazy    => 1,
		default => sub {
			join("_", grep { defined() } $prefix, shift()->$member(), $suffix)
		},
	);
}

1;

__END__

=head1 NAME

Reflex::Util::Methods - helper functions to generate methods

=head1 SYNOPSIS

	# Excerpt from Reflex::Role::Recving.

	package Reflex::Role::Recving;
	use MooseX::Role::Parameterized;
	use Reflex::Util::Methods qw(emit_an_event method_name);

	parameter handle => (
		isa     => 'Str',
		default => 'handle',
	);

	parameter cb_datagram => method_name("on", "handle", "writable");

	# (cb_datagram and cb_error omitted, among other things.)

	role {
		my $p = shift;
		my $h           = $p->handle();
		my $cb_datagram = $p->cb_datagram();
		my $cb_error    = $p->cb_error();

		# (Lots of stuff omitted here.)

		# Default callbacks that re-emit their parameters.
		method $cb_datagram => emit_an_event("data");
		method $cb_error    => emit_an_event("error");
	};

=head1 DESCRIPTION

Reflex::Util::Methods defines utility functions that generate methods
so developers don't have to.

=head2 emit_an_event

emit_an_event() generates a method body that will emit() a Reflex
event.  It was created to define default methods for Reflex roles.

emit_an_event() takes one parameter: the name of an event to emit.  It
returns an anonymous method that will emit that event, passing its
parameters with the event.  See the SYNOPSIS for an example.

=head2 method_name

method_name() generates a MooseX::Role::Parameterized declaration for
method name parameters.  Many Reflex roles accept callback and method
names for customization by their consumers.  method_name() eliminates
some of the tedium of declaring these parameters.

method_name() takes two or three parameters: a method prefix, a member
name, and an optional method suffix.  The parameter's default value
will be the prefix, the member's value, and suffix catenated with
underscores.

In the following example, if handle_name() is "XYZ", then cb_foo()
will be "on_XYZ_foo" by default.  It can of course be overridden by
the consumer.

	parameter handle_name => ( ... );
	cb_foo => method_name("on", "handle_name", "foo");

=head1 EXAMPLES

TODO

=head1 SEE ALSO

L<Reflex>

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
