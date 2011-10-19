#!/usr/bin/env perl
# vim: ts=2 sw=2 noexpandtab

# Asynchronous MySQL via DBD::mysql's mysql_fd() accessor.
#
# Run a long query, and do something with the results when they're
# ready.
#
# Also acts as a sample use case for Reflex::Filehandle.

use strict;
use warnings;
use feature 'say';

use Reflex::Interval;
use Reflex::Filehandle;
use DBI;

my $dbh = DBI->connect(
	'dbi:mysql:', undef, undef, {
		PrintError => 0,
		RaiseError => 1,
	}
);

my $sth = $dbh->prepare('SELECT SLEEP(3), 3', { async => 1 });
$sth->execute();

my $i = Reflex::Interval->new(
	interval => 1,
	on_tick  => sub { say 'timer fired!' },
);

my $mysql_watcher = Reflex::Filehandle->new(
	descriptor  => $dbh->mysql_fd(),
	rd          => 1,
	on_readable => sub {
		my $self = shift();
		say 'got data from MySQL';
		say join(' ', $sth->fetchrow_array);
		$self->emit(event => "data");
	},
);

$mysql_watcher->next();
