#!/usr/bin/env perl

# Using POE::Component::IRC.  That component requires the user to
# register for events.  The new PoeSession watcher is used to receive
# all events from the component.

use strict;
use warnings;

{
	package Bot;
	use Moose;
	extends 'Stage';
	use ObserverTrait;
	use PoeSession;

	use POE qw(Component::IRC);

	has component => (
		isa => 'Object|Undef',
		is  => 'rw',
	);

	has poco_watcher => (
		isa     => 'PoeSession',
		is      => 'rw',
		traits  => ['Observer'],
		role    => 'poco',
	);

	sub BUILD {
		my $self = shift;

		$self->component(
			POE::Component::IRC->spawn(
				nick    => "stage$$",
				ircname => "POE::Stage Test Bot",
				server  => "10.0.0.25",
			) || die "Drat: $!"
		);

		$self->poco_watcher(
			PoeSession->new(
				sid => $self->component()->session_id(),
			)
		);

		$self->run_within_session(
			sub {
				$self->component()->yield(register => "all");
				$self->component()->yield(connect  => {});
			}
		)
	}

	sub on_poco_irc_001 {
		my $self = shift;
		print "Connected.  Joining a channel...\n";
		$self->component->yield(join => "#room");
	}

	sub on_poco_irc_public {
		my ($self, $args) = @_;
		my ($who, $where, $what) = @$args;

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
