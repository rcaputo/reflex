#!/usr/bin/env perl
# vim: ts=2 sw=2 noexpandtab

# Using POE::Component::IRC.  That component requires the user to
# register for events.  The new Reflex::POE::Session watcher is used
# to receive all events from the component.

use strict;
use warnings;
use lib qw(../lib);

{
	package Bot;
	use Moose;
	extends 'Reflex::Base';
	use Reflex::POE::Session;
	use Reflex::Trait::Watched qw(watches);

	use POE qw(Component::IRC);

	has component => (
		isa => 'Object|Undef',
		is  => 'rw',
	);

	watches poco_watcher => (
		isa   => 'Reflex::POE::Session',
		role  => 'poco',
	);

	sub BUILD {
		my $self = shift;

		# This is only really necessary because we're using
		# POE::Component::IRC's OO interface.
		$self->component(
			POE::Component::IRC->spawn(
				nick    => "reflex_$$",
				ircname => "Reflex Test Bot",
				server  => "irc.perl.org",
			) || die "Drat: $!"
		);

		# Start a Reflex::POE::Session that will
		# subscribe to the IRC component.
		$self->poco_watcher(
			Reflex::POE::Session->new(
				sid => $self->component()->session_id(),
			)
		);

		# run_within_session() allows the component
		# to receive the correct $_[SENDER].
		$self->run_within_session(
			sub {
				# The following two lines work because
				# PoCo::IRC implements a yield() method.
				$self->component()->yield(register => "all");
				$self->component()->yield(connect  => {});
			}
		)
	}

	sub on_poco_irc_001 {
		my $self = shift;
		print "Connected.  Joining a channel...\n";
		$self->component->yield(join => "#reflex");
	}

	sub on_poco_irc_public {
		my ($self, $event) = @_;
		my ($who, $where, $what) = @{$event->args()}[0,1,2];

		my $nick = (split /!/, $who)[0];
		my $channel = $where->[0];

		if (my ($rot13) = $what =~ /^rot13 (.+)/) {
			$rot13 =~ tr[a-zA-Z][n-za-mN-ZA-M];
			$self->component->yield(privmsg => $channel => "$nick: $rot13");
		}
	}
}

Bot->new()->run_all();
exit;
