package Reflex::Eg::Inheritance::Plain;

use warnings;
use strict;
use base 'Reflex::Timeout';

sub on_done {
  shift()->reset();
  print scalar(localtime()), " - Subclass got timeout.\n";
}

__PACKAGE__->meta->make_immutable;

1;

__END__

=pod

=abstract Inheriting a Reflex timer with plain Perl.

=head1 SYNOPSIS

=example Reflex::Eg::Inheritance::Plain

Usage:

  perl -M[% doc.module %] -e '[% doc.module %]->new(delay => 1)->run_all'

=head1 DESCRIPTION

This module is nearly identical to Reflex::Eg::Inheritance::Moose.
It only differs in the mechanism of subclassing Reflex::Timeout.

=include Reflex::Eg::Inheritance::Moose DESCRIPTION

=cut

# vim: ts=2 sw=2 expandtab
