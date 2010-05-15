package EmitHelper;

use warnings;
use strict;

use Exporter;
use base 'Exporter';

our @EXPORT_OK = qw(default_emit);

# Helper function.  Returns a role method that emits an event.  Used
# as the default callback for many things.

sub default_emit {
	my ($cb_name, $event) = @_;
	return(
		$cb_name => sub {
			my ($self, $args) = @_;
			$self->emit(event => $event, args => $args);
		}
	);
}

1;
