package Reflex::UdpPeer;
use Moose;
with 'Reflex::Role::UdpPeer';

# Composes Reflex::Role::udpPeer into a class.
# Does nothing of its own.

no Moose;
__PACKAGE__->meta()->make_immutable();

1;

__END__

=head1 NAME

Reflex::UdpPeer - Base class for UDP networking peers.

=head1 SYNOPSIS

Inherit it.

	{
		package Reflex::UdpPeer::Echo;
		use Moose;
		extends 'Reflex::UdpPeer';

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

Use it as a helper.

	{
		package Reflex::UdpPeer::Echo;
		use Moose;
		extends 'Reflex::Object';
		use Reflex::UdpPeer;

		has port => (
			isa     => 'Int',
			is      => 'ro',
		);

		has peer => (
			isa     => 'Reflex::UdpPeer|Undef',
			is      => 'rw',
			traits  => ['Reflex::Trait::Observer'],
			setup   => sub {
				my $self = shift;
				Reflex::UdpPeer->new(port => $self->port());
			},
		);

		sub on_peer_datagram {
			my ($self, $args) = @_;
			my $data = $args->{datagram};

			if ($data =~ /^\s*shutdown\s*$/) {
				$self->peer(undef);
				return;
			}

			$self->peer()->send(
				datagram    => $data,
				remote_addr => $args->{remote_addr},
			);
		}

		sub on_peer_error {
			my ($self, $args) = @_;
			warn "$args->{op} error $args->{errnum}: $args->{errstr}";
			$self->peer(undef);
		}
	}

Compose objects with its base role.  See L<Reflex::Role::UdpPeer>.

=head1 DESCRIPTION

Reflex::UdpPeer is a base class for UDP network peers.

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
