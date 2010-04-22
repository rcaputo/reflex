package Reflex::Object;

use Moose;
with 'Reflex::Role::Object';

# Composes the Reflex::Role::Object into a class.
# Does nothing of its own.

1;

__END__

=head1 NAME

Reflex::Object - Base class for reactive (aka, event driven) objects.

=head1 SYNOPSIS

Using Moose:

	package Object;
	use Moose;
	extends 'Reflex::Object';

	...;

	1;

Not using Moose:

	package Object;
	use warnings;
	use strict;
	use base 'Reflex::Object';

	...;

	1;

=head1 DESCRIPTION

Reflex::Object is a base class for all Reflex objects, including many
of the ones that notify programs of external events.

Please see L<Reflex::Role::Object> for actual documentation.
Everything that Reflex::Object does comes from that role.  The
documentation is kept with the role in order for them to be near each
other.  It's so romantic!

=head1 SEE ALSO

L<Moose::Manual::Concepts>

L<Reflex>
L<Reflex::Role::Object>

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
