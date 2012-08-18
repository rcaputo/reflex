package EventBench::Method::Array; 

use strict;
use warnings; 
use Benchmark ':hireswallclock';

sub receive_event {
	my ($arg1, $arg2) = @_; 
	our($sum); 
	
	$sum += $arg1 + $arg2; 
}

return sub {
	my (@testData) = @_; 
	our $sum = 0; 
	my $bench; 
	
	$bench = timeit(1, sub {
		
		foreach(@testData) {
			receive_event($_->[0], $_->[1]); 
		}
	});	
	
	return { bench => $bench, sum => $sum }; 
}; 