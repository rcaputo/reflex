package Reflex::POE::Session;

use Moose;
extends 'Reflex::Object';
use Scalar::Util qw(weaken);
use POE::Session; # for ARG0

my %session_id_to_object;

has sid => (
	isa => 'Str',
	is  => 'ro',
);

sub BUILD {
	my $self = shift;

	$session_id_to_object{$self->sid()}{$self} = $self;
	weaken $session_id_to_object{$self->sid()}{$self};
}

sub DEMOLISH {
	my $self = shift;
	delete $session_id_to_object{$self->sid()}{$self};
	delete $session_id_to_object{$self->sid()} unless (
		keys %{$session_id_to_object{$self->sid()}}
	);
}

sub deliver {
	my ($class, $sender_id, $event, $args) = @_;

	# Not a session anyone is interested in.
	return unless exists $session_id_to_object{$sender_id};

	foreach my $self (values %{$session_id_to_object{$sender_id}}) {
		$self->emit(
			event => $event,
			args  => { map { $_ => $args->[$_] } (0..$#$args) },
		);
	}
}

1;

__END__

=head1 NAME

Reflex::POE::Session - Observe events from a POE::Session object.

=head1 SYNOPSIS

# Not a complete example.
# Please see eg-13-irc-bot.pl in the examples for one.

	has poco_watcher => (
		isa     => 'Reflex::POE::Session',
		is      => 'rw',
		traits  => ['Reflex::Trait::Observer'],
		role    => 'poco',
	);

	sub BUILD {
		my $self = shift;

		$self->component(
			POE::Component::IRC->spawn(
				nick    => "reflex_$$",
				ircname => "Reflex Test Bot",
				server  => "10.0.0.25",
			) || die "Drat: $!"
		);

		$self->poco_watcher(
			Reflex::POE::Session->new(
				sid => $self->component()->session_id(),
			)
		);

		$self->run_within_session(
			sub {
				$self->component()->yield(register => "all");
				$self->component()->yield(connect  => {});
			}
		)
	}

TODO - Either complete the example, or find a shorter one.

=head1 DESCRIPTION

Reflex::POE::Session allows a Reflex::Object to receive events from a
specific POE::Session instance, identified by the session's ID.  In
the future it may also limit the events it sees to allow better
performance.

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
