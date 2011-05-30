package Reflex::Trait::Observed;
# vim: ts=2 sw=2 noexpandtab

use Moose::Role;
with qw(Reflex::Trait::Watched);

use Moose::Exporter;
Moose::Exporter->setup_import_methods( with_caller => [ qw( observes ) ]);

warn(
	"[ Reflex::Trait::Observed is deprecated.     ]\n",
	"[ Please use Reflex::Trait::Watched instead. ]\n",
);

sub observes { goto \&watches }

package Moose::Meta::Attribute::Custom::Trait::Reflex::Trait::Observed;
sub register_implementation { 'Reflex::Trait::Observed' }

1;

__END__

=head1 NAME

Reflex::Trait::Observed - Automaticall watch Reflex objects.

=head1 SYMOPSIS

See L<Reflex::Trait::Watched>.

=head1 DESCRIPTION

First, this trait is deprecated.  Please use Reflex::Trait::Watched
instead.

This trait exists for backwards compatibility, allowing existing code
to use Reflex::Trait::Watched by its old name.  New code should use
Reflex::Trait::Watched directly.

=head1 SEE ALSO

L<Reflex>
L<Reflex::Trait::Watched>

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
