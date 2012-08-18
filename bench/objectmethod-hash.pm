package EventBench::ObjectMethod::Hash; 

use strict;
use warnings; 
use Benchmark ':hireswallclock';

sub new {
	return bless({}, $_[0]);
}

sub receive_event {
	my ($self, %event) = @_; 
	our $sum;
	
	$sum += $event{arg1} + $event{arg2}; 
}

return sub {
	my (@testData) = @_;
	my $test = EventBench::ObjectMethod::Hash->new; 
	our $sum = 0; 
	my $bench; 
	
	$bench = timeit(1, sub {
		foreach(@testData) {
			$test->receive_event(arg1 => $_->[0], arg2 => $_->[1]); 
		}
	});	
	
	return { bench => $bench, sum => $sum }; 
}; 