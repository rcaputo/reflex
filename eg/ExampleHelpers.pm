## Used in the examples to reduce LOC by declaring fucntions that are used
## over and over in this module

package ExampleHelpers;

use warnings;
use strict;

use POSIX qw(strftime);
use Exporter;
use base qw(Exporter);

our @EXPORT_OK = qw(eg_say eg_object);

sub eg_say {
	my $message = join("", @_);
	print strftime("%F %T", localtime()), " - ", $message, "\n";
}

sub eg_object {
	my $name = shift;
	return ExampleObject->new($name);
}

# An example object.

{
	package ExampleObject;

	use warnings;
	use strict;

	sub new {
		my ($class, $name) = @_;
		return bless {
			name => $name,
		}, $class;
	}

	sub handler_method {
		my $self = shift;
		ExampleHelpers::eg_say("$self->{name} handled an event");
	}
}

1;
