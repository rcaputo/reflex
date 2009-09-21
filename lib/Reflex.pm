package Reflex;

use warnings;
use strict;

use Carp qw(croak);

our $VERSION = '0.001';

sub import {
  my $class = shift;
  my $caller_package = caller();

  # Use the packages in the caller's package.
  # TODO - I think lexical magic isn't supported.

  eval join(
    "; ",
    "package $caller_package",
    map { "use $class\::$_" }
    @_
  );


  # Rewrite the error so that it comes from the caller.
  if ($@) {
    my $msg = $@;
    $msg =~ s/(\(\@INC contains.*?\)) at .*/$1/s;
    croak $msg;
  }
}

1;

__END__

=head1 NAME

Reflex - Reactive classes for flexible programs.

=head1 SYNOPSIS

  {
    package App;
    use Moose;
    extends 'Reflex::Object';
    use Reflex::Timer;

    has ticker => (
      isa     => 'Reflex::Timer',
      is      => 'rw',
      setup   => { interval => 1, auto_repeat => 1 },
      traits  => [ 'Reflex::Trait::Observer' ],
    );

    sub on_ticker_tick {
      print "tick at ", scalar(localtime), "...\n";
    }
  }

  exit App->new()->run_all();

=head1 DESCRIPTION

Reflex is a suite of classes to help programmers write reactive
programs.  More to come

=head1 GETTING HELP

POE's mailing list.
Channel #poe on irc.perl.org.

=head1 ACKNOWLEDGEMENTS

irc.perl.org channel #moose and #poe.  The former for assisting in
learning their fine libraries, sometimes against everyone's better
judgement.  The latter for putting up with lengthy and sometimes
irrelevant design discussion for oh so long.

=head1 SEE ALSO

Moose
POE
Ohlo
Reflex namespace on CPAN.
Links to tutorials & reviews.
Home page for Reflex.

=head1 BUGS

TODO - Link to Reflex's RT queue.  Explain how to send e-mail, too.

=head1 AUTHORS

Rocco Caputo
Point out that it's a FOSS project, and anyone may contribute.

=head2 OTHER CONTRIBUTORS

List here, when there are some.

=head1 COPYRIGHT AND LICCENSE

Copyright 2009 by Rocco Caputo.

Reflex is free software.  You may redistribute and/or modify it under
the same terms as Perl itself.

TODO - Recommended best practice for licenses.

=cut
