package EventBench::Method::Hash; 

use strict;
use warnings; 
use Benchmark ':hireswallclock';

sub receive_event {
	my (%event) = @_; 
	our $sum; 
	
	$sum += $event{arg1} + $event{arg2}; 
}

return sub {
	my (@testData) = @_; 
	our $sum = 0; 
	my $bench; 
	
	$bench = timeit(1, sub {
		foreach(@testData) {
			receive_event(arg1 => $_->[0], arg2 => $_->[1]); 
		}
	});	
	
	return { bench => $bench, sum => $sum }; 
}; 