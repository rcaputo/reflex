package Reflex::Timeout;
# vim: ts=2 sw=2 noexpandtab

use Moose;
extends 'Reflex::Base';
use Reflex::Callbacks qw(make_emitter);

has delay       => ( isa => 'Num', is  => 'ro' );
has auto_start  => ( isa => 'Bool', is => 'ro', default => 1 );

with 'Reflex::Role::Timeout' => {
	att_auto_start => "auto_start",
	att_delay      => "delay",
	cb_timeout     => make_emitter(on_done => "done"),
	method_reset   => "reset",
	method_start   => "start",
	method_stop    => "stop",
};

1;

__END__

=head1 NAME

Reflex::Timeout - A stand-alone single-shot delayed callback

=head1 SYNOPSIS

	#!/usr/bin/env perl

	use warnings;
	use strict;

	use Reflex::Timeout;

	my $to = Reflex::Timeout->new(
		delay   => 1,
		on_done => \&handle_timeout,
	);

	Reflex->run_all();
	exit;

	sub handle_timeout {
		print "got timeout\n";
		$to->reset();
	}

=head1 DESCRIPTION

Reflex::Timeout invokes a callback after a specified amount of time
has elapsed.  Timeouts may be stopped, restarted, or reset so they
must again wait the full delay period.  Resetting is especially
useful, for example whenever input arrives.

=head2 Public Attributes

=head3 delay

Implemented and documented by L<Reflex::Role::Timeout/delay>.

=head2 Public Callbacks

=head3 on_done

Implemented and documented by L<Reflex::Role::Timeout/cb_timeout>.

=head2 Public Methods

=head3 reset

Implemented and documented by L<Reflex::Role::Timeout/method_reset>.

=head3 start

Implemented and documented by L<Reflex::Role::Timeout/method_start>.

=head3 stop

Implemented and documented by L<Reflex::Role::Timeout/method_stop>.

=head1 EXAMPLES

TODO - Link to them.

=head1 SEE ALSO

L<Reflex>
L<Reflex::Role>
L<Reflex::Role::Interval>
L<Reflex::Role::Timeout>
L<Reflex::Role::Wakeup>
L<Reflex::Interval>
L<Reflex::Wakeup>

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
