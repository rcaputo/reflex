package EventBench::ObjectMethod::CBManager; 

use strict;
use warnings; 
use Benchmark ':hireswallclock';
use Scalar::Util qw(weaken); 

sub new {
	my $self = bless({ }, $_[0]);
	our $sum; 
	
	$self->{handlers}->{sum} = $self->weakcb(sub {
		my ($self, %event) = @_; 
		
		$sum += $event{arg1} + $event{arg2}; 
	}); 
	
	return $self; 
}

sub receive_event {
	my ($self, %event) = @_;
	
	$self->{handlers}->{$event{name}}->($self, %event); 
}

#pass in code ref or method name as string 
sub weakcb {
	my ($self, $cb) = @_; 
	
	weaken($self); 
	
	return sub {
		my ($self) = shift(@_); 
		
		die "expected weak reference to self to be valid but it was undefined" unless defined $self; 
		
		return $self->$cb(@_);
	};
}

return sub {
	my (@testData) = @_; 
	my $test = EventBench::ObjectMethod::CBManager->new; 
	my $bench; 
	our $sum; 
	
	$bench = timeit(1, sub {
		our $sum = 0; 
		
		foreach(@testData) {
			$test->receive_event(name => 'sum', arg1 => $_->[0], arg2 => $_->[1]);
		}
	});	
	
	return { bench => $bench, sum => $sum }; 
}; 