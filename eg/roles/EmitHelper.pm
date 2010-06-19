package EmitHelper;

use warnings;
use strict;

use Exporter;
use base 'Exporter';

our @EXPORT_OK = qw(emit_by_default);

# Helper function.  Returns a role method that emits an event.  Used
# as the default callback for many things.

sub emit_by_default {
	my ($cb_name, $event) = @_;
	return(
		$cb_name => sub {
			my ($self, $args) = @_;
			$self->emit(event => $event, args => $args);
		}
	);
}

1;
