package Reflex::Base;
# vim: ts=2 sw=2 noexpandtab

use Moose;
with 'Reflex::Role::Reactive';

# Composes the Reflex::Role::Reactive into a class.
# Does nothing of its own.

1;

__END__

=head1 NAME

Reflex::Base - Base class for reactive (aka, event driven) objects.

=head1 SYNOPSIS

Using Moose:

	package Object;
	use Moose;
	extends 'Reflex::Base';

	...;

	1;

Not using Moose:

	package Object;
	use warnings;
	use strict;
	use base 'Reflex::Base';

	...;

	1;

=head1 DESCRIPTION

Reflex::Base is a base class for all reactive Reflex objects,
including many of the ones that notify programs of external events.

Please see L<Reflex::Role::Reactive>, which contains the
implementation and detailed documentation for this class.  The
documentation is kept with the role in order for them to be near each
other.  It's so romantic!

=head1 SEE ALSO

L<Moose::Manual::Concepts>

L<Reflex>
L<Reflex::Role::Reactive>

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
