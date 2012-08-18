#!/usr/bin/env perl

use lib qw(bench/lib);

use strict;
use warnings; 
use Data::Dumper; 

$ENV{EVENT_SEND_COUNT} = 500000 unless exists $ENV{EVENT_SEND_COUNT}; 
$ENV{MIN_TEST_TIME} = 60 unless exists $ENV{MIN_TEST_TIME}; 
$ENV{BENCH_DIR} = 'bench' unless exists $ENV{BENCH_DIR}; 

logger("Configuration: $ENV{EVENT_SEND_COUNT} events and $ENV{MIN_TEST_TIME} seconds minimum test time\n");

my @results = doTests();
my $error = shift(@results); 
doLog(@results); 
exit($error); 

exit(0); 

sub logger {
	print STDERR @_;
}

sub genFiles {
	my ($dir) = @_; 
	my $dh; 
	my @paths; 
	
	die "$dir is not a directory or is not accessable" unless -d $dir; 

	die "Could not opendir($dir): $!" unless opendir($dh, $dir); 
	
	foreach(readdir($dh)) {
		next if m/^\./;
		next if -d $_; 
				
		push(@paths, "$dir/$_");
	}
	
	die "Could not closedir($dir): $!" unless closedir($dh); 
	
	return @paths; 
}

sub genTests {
	my @files; 
	my @buf; 
		
	if (scalar(@ARGV) > 0) {
		@files = @ARGV; 
	} else {
		logger("Loading benchmarks from $ENV{BENCH_DIR}/... ");
		@files = genFiles($ENV{BENCH_DIR});
		logger("found ", scalar(@files), " files\n");
	}
	
	foreach(@files) {
		my %test = ( file => $_ ); 	
	
		logger("loading $_... ");
	
		$test{cb} = require $_; 
		
		logger("done\n");
		
		push(@buf, \%test); 
	}
	
	return @buf; 
}

sub randomInt {
	return int(rand(10)); 
}

sub genData {
	my @buf = @_; 
	
	logger("Generating test data... ");

	foreach(1 .. $ENV{EVENT_SEND_COUNT}) {
		push(@buf, [ randomInt(), randomInt() ]);
	}
	
	logger("done\n");
	return @buf; 	
}

sub sumData {
	my $sum = 0;
	
	foreach(@_) {
		$sum += $_->[0] + $_->[1]; 
	}
	
	return $sum; 
}

sub doTests {	
	my @tests = genTests(); 
	my @testData = genData(); 
	my $sum = sumData(@testData); 
	my $error = 0; 
	
	foreach(@tests) {
		my $seconds = 0; 
		my $eventCount = 0; 
		my $iterations = 0; 
	
		logger("Measuring $_->{file}... ");
		
		while(1) {
			my ($results, $bench); 
			
			$iterations++; 
			
			$results = $_->{cb}(@testData);
			$bench = $results->{bench}; 
			
			if ($results->{sum} != $sum) {
				logger("INVALID SUM $results->{sum} != $sum "); 
				$error = 1; 
			}
			
			$seconds += $bench->[0];
			$eventCount += $ENV{EVENT_SEND_COUNT}; 
					
			if ($seconds >= $ENV{MIN_TEST_TIME}) {
				last; 
			}
			
			logger("$iterations "); 
		}
			
		$_->{analysis} = {
			cpuTime => $seconds,
			eventCount => $eventCount,
			eventsPerSecond => $eventCount / $seconds,
		}; 
			
		logger("done\n");
	}
	
	return ($error, @tests);
}

sub doLog {
	my (@tests) = @_; 
	
	logger("Report format: file\tevents per second\tcost of solution\n");
	
	foreach(sort({ $b->{analysis}->{eventsPerSecond} <=> $a->{analysis}->{eventsPerSecond} } @tests)) {
		my $analysis = $_->{analysis}; 
		my $eventsPerSecond = int($analysis->{eventsPerSecond}); 
		our $fastest; 
		my $cost; 
		
		if (! defined($fastest)) {
			$fastest = $eventsPerSecond;
		}
		
		$cost = $fastest / $eventsPerSecond;  
			
		print "$_->{file}\t$eventsPerSecond\t$cost\n";
	}
}

