package Reflex::Eg::Inheritance::Moose;

use Moose;
extends 'Reflex::Timeout';

sub on_done {
  shift()->reset();
  print scalar(localtime()), " - Subclass got timeout.\n";
}

__PACKAGE__->meta->make_immutable;

1;

__END__

=pod

=head1 NAME

Reflex::Eg::Inheritance::Moose - Inheriting a Reflex timer using Moose.

=head1 SYNOPSIS

Usage:

  perl -M[% doc.module %] -e '[% doc.module %]->new(delay => 1)->run_all'

=head1 DESCRIPTION

Reflex::Timeout objects normally go dormant after the first time they
call on_done().

[% doc.module %] implements a simple periodic timer by subclassing and
overriding Reflex::Timeout's on_done() callback.  The act of finishing
the timeout causes itself to be reset.

Since this is an example, the subclass also prints a message so it's
apparent it works.

This is a relatively silly exercise.
Reflex::Interval already implements a periodic interval timer.

=cut

# vim: ts=2 sw=2 expandtab
