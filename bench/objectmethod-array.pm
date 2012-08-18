package EventBench::ObjectMethod::Array; 

use strict;
use warnings; 
use Benchmark ':hireswallclock';

sub new {
	return bless({}, $_[0]);
}

sub receive_event {
	my ($self, $arg1, $arg2) = @_; 
	our $sum; 
	
	$sum += $arg1 + $arg2; 
}

return sub {
	my (@testData) = @_; 
	my $test = EventBench::ObjectMethod::Array->new; 
	our $sum = 0; 
	my $bench; 
	
	$bench = timeit(1, sub {
		
		foreach(@testData) {
			$test->receive_event($_->[0], $_->[1]); 
		}
	});	
	
	return { bench => $bench, sum => $sum }; 
}; 