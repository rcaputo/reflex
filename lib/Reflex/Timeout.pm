package Reflex::Timeout;

use Moose;
extends 'Reflex::Base';

has delay       => ( isa => 'Num', is  => 'ro' );
has auto_start  => ( isa => 'Bool', is => 'ro', default => 1 );

# TODO - There is a flaw in the design.
#
# Reflex::Timeout = cb_timeout => "on_done"
# Reflex::Role::Timeout = method_emit $cb_timeout => $p->ev_done()
#
# However, the user's on_done => callback() only works because the
# emitted event is "done".  And this "done" is a constant, which means
# we pretty much have to use "on_done" here, or the chain of events is
# broken.
#
# Somehow we must make the chain of events work no matter what
# cb_timeout is set to here.

with 'Reflex::Role::Timeout' => {
	delay         => "delay",
	cb_timeout    => "on_done",
	ev_timeout    => "done",
	auto_start    => "auto_start",
	method_start  => "start",
	method_stop   => "stop",
	method_reset  => "reset",
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
