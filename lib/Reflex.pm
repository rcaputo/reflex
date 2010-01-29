package Reflex;

use warnings;
use strict;

use Carp qw(croak);

our $VERSION = '0.003';

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
programs.  The project has some goals:

=over 2

=item * Be concise.

=item * Be convenient.

=item * Be portable.

=item * Be fast.

=item * Don't get in the way.

=item * Release early, and release often.

=back

Sorry for the lack of documentation.  It conflicted with releasing
early.  Contributions are very much welcome.  Give the project a
reason to release often.

TODO - Complete the documentation.

Reflex is "reactive" in the sense that it is an implementation of the
"reactor" pattern.  http://en.wikipedia.org/wiki/Reactor_pattern

=head1 GETTING HELP

See irc.perl.org #moose for help with Moose.

See irc.perl.org #poe for help with POE and Reflex.

Support is officially available from POE's mailing list as well.  Send
a blank message to
L<poe-subscribe@perl.org|mailto:poe-subscribe@perl.org>
to join.

=head1 ACKNOWLEDGEMENTS

irc.perl.org channel
L<#moose|irc://irc.perl.org/moose>
and
L<#poe|irc://irc.perl.org/moose>.
The former for assisting in learning their fine libraries, sometimes
against everyone's better judgement.  The latter for putting up with
lengthy and sometimes irrelevant design discussion for oh so long.

=head1 SEE ALSO

L<Moose>, L<POE>, the Reflex namespace on CPAN.

TODO - Set up ohlo.

TODO - Set up CIA.

TODO - Set up home page.

=head1 BUGS

We appreciate your feedback, bug reports, feature requests, patches
and kudos.  You may enter them into our request tracker by following
the instructions at
L<https://rt.cpan.org/Dist/Display.html?&Queue=Reflex>.

We also accept e-mail at
L<bug-Reflex@rt.cpan.org|mailto:bug-Reflex@rt.cpan.org>.

=head1 AUTHORS

Rocco Caputo, and a (hopefully) growing cadre of contributors---
perhaps including you.  Reflex is open source, and we welcome
involvement.

=head2 OTHER CONTRIBUTORS

Nobody yet.  As of this writing, Reflex has only just been released.
The repository is publicly available for your hacking pleasure:

=over 2

=item * L<https://github.com/rcaputo/reflex>

=item * L<http://gitorious.org/reflex>

=back

=head1 TODO

Please browse the source for the TODO marker.  Some are visible in the
documentation, and others are sprinlked around in the code's comments.

=head1 COPYRIGHT AND LICCENSE

Copyright 2009 by Rocco Caputo.

Reflex is free software.  You may redistribute and/or modify it under
the same terms as Perl itself.

TODO - Use the latest recommended best practice for licenses.

=cut
