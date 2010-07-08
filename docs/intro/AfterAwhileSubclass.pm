package AfterAwhileSubclass;

use warnings;
use strict;
use base 'AfterAwhileClass';

sub on_done {
	print "subclass overrode on_done\n";
}

1;
