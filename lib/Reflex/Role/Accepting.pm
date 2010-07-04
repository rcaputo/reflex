package Reflex::Role::Accepting;
use MooseX::Role::Parameterized;
use Reflex::Util::Methods qw(emit_an_event emit_and_stopped method_name);

parameter listener => (
	isa     => 'Str',
	default => 'listener',
);

parameter cb_accept     => method_name("on", "listener", "accept");
parameter cb_error      => method_name("on", "listener", "error");
parameter method_pause  => method_name("pause", "listener", undef);
parameter method_resume => method_name("resume", "listener", undef);
parameter method_stop   => method_name("stop", "listener", undef);

role {
	my $p = shift;

	my $listener  = $p->listener();
	my $cb_accept = $p->cb_accept();
	my $cb_error  = $p->cb_error();

	with 'Reflex::Role::Readable' => {
		handle        => $listener,
		active        => 1,
		method_pause  => $p->method_pause(),
		method_resume => $p->method_resume(),
		method_stop   => $p->method_stop(),
	};

	method "on_${listener}_readable" => sub {
		my ($self, $args) = @_;

		my $peer = accept(my ($socket), $args->{handle});

		if ($peer) {
			$self->$cb_accept(
				{
					peer    => $peer,
					socket  => $socket,
				}
			);
			return;
		}

		$self->$cb_error(
			{
				errnum => ($! + 0),
				errstr => "$!",
				errfun => "accept",
			}
		);
		return;
	};

	method $cb_accept => emit_an_event("accept");
	method $cb_error  => emit_and_stopped("error");  # TODO - Retryable ones.
};

1;
