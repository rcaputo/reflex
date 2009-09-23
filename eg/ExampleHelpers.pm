package ExampleHelpers;

use warnings;
use strict;

use POSIX qw(strftime);
use Exporter;
use base qw(Exporter);

our @EXPORT_OK = qw(tell);

sub tell {
	my $message = join("", @_);
	print strftime("%F %T", localtime()), " - ", $message, "\n";
}

1;
