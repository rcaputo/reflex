package Reflex::Util::Methods;

use warnings;
use strict;

use Exporter;
use base 'Exporter';

our @EXPORT_OK = qw(emit_an_event);

sub emit_an_event {
	my ($event_name) = @_;
	return(
		$cb_name => sub {
			my ($self, $args) = @_;
			$self->emit(event => $event_name, args => $args);
		}
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
	use Reflex::Util::Methods qw(emit_an_event);

	parameter handle => (
		isa     => 'Str',
		default => 'handle',
	);

	# (cb_datagram and cb_error omitted, among other things.)

	role {
		my $p = shift;
		my $h           = $p->handle();
		my $cb_datagram = $p->cb_datagram();
		my $cb_error    = $p->cb_error();

		# (Lots of stuff omitted here.)

		# Default callbacks that re-emit their parameters.
		method $cb_datagram => emit_an_event("${h}_data");
		method $cb_error    => emit_an_event("${h}_error");
	};

=head1 DESCRIPTION

Reflex::Util::Methods defines utility functions that generate methods
so developers don't have to.

=head2 emit_and_event

emit_and_event() takes one parameter: the name of an event to emit.
It returns an anonymous method that will emit that event, passing its
parameters with the event.

emit_an_event() methods take two parameters: $self and an anonymous
hashref of named parameters.

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
