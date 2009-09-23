package Reflex::Role::UdpPeer;
use Moose::Role;
with 'Reflex::Role::Object';
use Reflex::Handle;

has port => (
	isa => 'Int',
	is  => 'ro',
);

has handle => (
	isa     => 'Reflex::Handle|Undef',
	is      => 'rw',
	traits  => ['Reflex::Trait::Observer'],
	role    => 'remote',
);

has max_datagram_size => (
	isa     => 'Int',
	is      => 'rw',
	default => 16384,
);

after 'BUILD' => sub {
	my $self = shift;

	$self->handle(
		Reflex::Handle->new(
			handle => IO::Socket::INET->new(
				Proto     => 'udp',
				LocalPort => $self->port(),
			),
			rd => 1,
		)
	);
	undef;
};

sub on_remote_read {
	my ($self, $args) = @_;

	my $remote_address = recv(
		$args->{handle},
		my $datagram = "",
		$self->max_datagram_size(),
		0
	);

	$self->emit(
		event => "datagram",
		args => {
			datagram    => $datagram,
			remote_addr => $remote_address,
		},
	);
}

sub send {
	my ($self, @args) = @_;

	my $args = $self->_check_args(
		\@args,
		[ 'datagram', 'remote_addr' ],
		[ ],
	);

	return if send(
		$self->handle()->handle(), # TODO - Ugh!
		$args->{datagram},
		0,
		$args->{remote_addr},
	) == length($args->{datagram});

	$self->emit(
		event => "error",
		args  => {
			op      => "send",
			errnum  => $! + 0,
			errstr  => "$!",
		},
	);
}

sub destruct {
	my $self = shift;
	$self->handle(undef);
}

no Moose;
#__PACKAGE__->meta()->make_immutable();

1;

__END__

=head1 NAME

Reflex::Role::UdpPeer - Turn an object into a UDP network peer.

=head1 SYNOPSIS

	{
		package Reflex::UdpPeer::Echo;
		use Moose;
		with 'Reflex::Role::UdpPeer';

		sub on_my_datagram {
			my ($self, $args) = @_;
			my $data = $args->{datagram};

			if ($data =~ /^\s*shutdown\s*$/) {
				$self->destruct();
				return;
			}

			$self->send(
				datagram    => $data,
				remote_addr => $args->{remote_addr},
			);
		}

		sub on_my_error {
			my ($self, $args) = @_;
			warn "$args->{op} error $args->{errnum}: $args->{errstr}";
			$self->destruct();
		}
	}

=head1 DESCRIPTION

Reflex::Role::UdpPeer is an alternative to inheriting from
Reflex::UdpPeer directly.

TODO - Complete the documentation.

=head1 GETTING HELP

L<Reflex/GETTING HELP>

=head1 ACKNOWLEDGEMENTS

L<Reflex/ACKNOWLEDGEMENTS>

=head1 SEE ALSO

L<Reflex> and L<Reflex/SEE ALSO>

=head1 BUGS

L<Reflex/BUGS>

=head1 CORE AUTHORS

L<Reflex/CORE AUTHORS>

=head1 OTHER CONTRIBUTORS

L<Reflex/OTHER CONTRIBUTORS>

=head1 COPYRIGHT AND LICENSE

L<Reflex/COPYRIGHT AND LICENSE>

=cut
