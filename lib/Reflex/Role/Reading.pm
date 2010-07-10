package Reflex::Role::Reading;
use MooseX::Role::Parameterized;
use Reflex::Util::Methods qw(emit_an_event emit_and_stopped method_name);

parameter handle => (
	isa     => 'Str',
	default => 'handle',
);

parameter cb_data     => method_name("on", "handle", "data");
parameter cb_error    => method_name("on", "handle", "error");
parameter cb_closed   => method_name("on", "handle", "closed");

# Matches Reflex::Role::Readable's default callback.
parameter method_read => method_name("on", "handle", "readable");

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
	method $cb_data   => emit_an_event("data");
	#method $cb_error  => emit_and_stopped("error");
	method $cb_closed => emit_and_stopped("closed");
};

1;
