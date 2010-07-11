package Reflex::Role::Reading;
use Reflex::Role;

attribute_parameter handle    => "handle";

callback_parameter cb_data    => qw( on handle data );
callback_parameter cb_error   => qw( on handle error );
callback_parameter cb_closed  => qw( on handle closed );

# Matches Reflex::Role::Readable's default callback.
# TODO - Any way we can coordinate this so it's obvious in the code
# but not too verbose?
method_parameter  method_read => qw( on handle readable );

role {
	my $p = shift;

	my $h           = $p->handle();
	my $cb_data     = $p->cb_data();
	my $cb_error    = $p->cb_error();
	my $cb_closed   = $p->cb_closed();
	my $method_read = $p->method_read();

	requires $cb_error;

	method $method_read => sub {
		my ($self, $arg) = @_;

		my $octet_count = sysread($arg->{handle}, my $buffer = "", 65536);

		# Got data.
		if ($octet_count) {
			$self->$cb_data({ data => $buffer });
			return;
		}

		# EOF
		if (defined $octet_count) {
			$self->$cb_closed({ });
			return;
		}

		# Quelle erreur!
		$self->$cb_error(
			{
				errnum => ($! + 0),
				errstr => "$!",
				errfun => "sysread",
			}
		);
	};

	# Default callbacks that re-emit their parameters.
	method_emit           $cb_data    => "data";
	method_emit_and_stop  $cb_closed  => "closed";
};

1;
