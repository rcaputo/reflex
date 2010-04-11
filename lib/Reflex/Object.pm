package Reflex::Object;

use Moose;
with 'Reflex::Role::Object';

# Composes the Reflex::Role::Object into a class.
# Does nothing of its own.

1;

__END__

=head1 NAME

Reflex::Object - Base class for reactive objects.

=head1 SYNOPSIS

	{
		package Object;
		use Moose;
		extends 'Reflex::Object';
		...;
	}

=head1 DESCRIPTION

Reflex::Object is the base class for all Reflex objects, including
many of the event watchers.

Please see L<Reflex::Role::Object> for actual documentation.  The role
implements Reflex::Object's internals.

TODO - Complete the documeentation.

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
