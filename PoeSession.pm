package PoeSession;

use Moose;
extends 'Stage';
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
			args  => [ @$args ],
		);
	}
}

1;
