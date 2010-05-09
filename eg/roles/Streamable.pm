package Streamable;
use MooseX::Role::Parameterized;

use Scalar::Util qw(weaken);

parameter handle => (
	isa     => 'Str',
	default => 'handle',
);

role {
	my $p = shift;

	with Readable => {
		handle => $p->handle(),
		active => 1,
	};

	with Writable => {
		handle => $p->handle(),
	};

	method "on_" . $p->handle() . "_readable" => sub {
		my ($self, $arg) = @_;

		my $octet_count = sysread($arg->{handle}, my $buffer = "", 65536);
		if ($octet_count) {
			$self->emit(
				event => $p->handle() . "_data",
				args => {
					data => $buffer,
					handle => $arg->{handle},
				},
			);
			return;
		}

		return if defined $octet_count;
		warn $!;
	}
};

1;
