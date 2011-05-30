package Reflex::Callback::CodeRef;
# vim: ts=2 sw=2 noexpandtab

use Moose;
extends 'Reflex::Callback';

has code_ref => (
	is => 'ro',
	isa => 'CodeRef',
	required => 1,
);

sub deliver {
	my ($self, $event, $arg) = @_;
	$self->code_ref()->($self->object(), $arg);
}

1;

__END__

=head1 NAME

Reflex::Callback::CodeRef - Callback adapter for plain code references

=head1 SYNOPSIS

Used within Reflex:

	use Reflex::Callbacks qw(cb_coderef);

	my $ct = Reflex::Interval->new(
		interval    => 1 + rand(),
		auto_repeat => 1,
		on_tick     => cb_coderef {
			print "coderef callback triggered\n";
		},
	);

	$ct->run_all();

Low-level usage:

	sub callback {
		my $arg = shift;
		print "hello, $arg->{name}\n";
	}

	use Reflex::Callback;
	my $cb = Reflex::Callback::CodeRef->new( code_ref => \&code );
	$cb->deliver(greet => { name => "world" });

=head1 DESCRIPTION

Reflex::Callback::CodeRef maps the generic Reflex::Callback interface
to plain coderef callbacks.  Reflex::Callbacks' cb_coderef() function
and other syntactic sweeteners hide the specifics.

=head2 new

Reflex::Callback::CodeRef's constructor takes a single named
parameter, "code_ref", which should contain the coderef to be called
by deliver().

=head2 deliver

Reflex::Callback::CodeRef's deliver() method invokes the coderef
supplied during the callback's construction.  deliver() takes two
positional parameters: an event name (which is not currently used for
coderef callbacks), and a hashref of named parameters to be passed to
the callback.

deliver() returns whatever the coderef does.

=head1 SEE ALSO

L<Reflex>
L<Reflex::Callback> documents the base class' generic interface.
L<Reflex::Callbacks> documents callback convenience functions.

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
