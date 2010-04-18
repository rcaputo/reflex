package Reflex::Callback;

use Moose;
use Reflex::Object;

# It's a class if it's a Str.
has object => (
	is        => 'ro',
	isa       => 'Object|Str',  # TODO - Reflex::Object|Str
	weak_ref  => 1,
);

1;

__END__

=head1 NAME

Reflex::Callback - Generic callback adapters to simplify calling back

=head1 SYNOPSIS

Varies.  See individual Reflex::Callback subclasses.

=head1 DESCRIPTION

Reflex::Callback and its subclasses implement the different types of
calbacks that Reflex supports.  Reflex::Callbacks provides convenience
functions that are almost always used instead of Reflex::Callback
objects.

Reflex::Callback's generic interface is a constructor and a single
method, deliver(), which routes its parameters to their destination.
Subclasses may implement additional methods to support specific use
cases.

=head2 new

Constructor parameters vary from one subclass to another.

=head2 deliver

All deliver() methods take two positional parameters: the name of an
event being delivered, and a hashref of named parameters for the
callback.  Not all subclasses actually use the event name, however.

=head1 SEE ALSO

L<Reflex>
L<Reflex::Callback::CodeRef>
L<Reflex::Callback::Method>
L<Reflex::Callback::Promise>
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
