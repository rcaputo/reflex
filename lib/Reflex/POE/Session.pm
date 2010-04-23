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

This sample usage is not a complete program.  The rest of the program
exists in eg-13-irc-bot.pl, in the tarball's eg directory.

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

=head1 DESCRIPTION

Reflex::POE::Session allows a Reflex::Object to receive events from a
specific POE::Session instance, identified by the session's ID.

Authors are encouraged to encapsulate POE sessions within Reflex
objects.  Most users should not need use Reflex::POE::Session (or
other Reflex::POE helpers) directly.

=head2 Public Attributes

=head3 sid

The "sid" must contain the ID of the POE::Session to be watched.  This
is in fact how Reflex::POE::Session knows which session to watch.  See
L<POE> for more information about session IDs.

=head2 Public Events

Reflex::POE::Session will emit() events on behalf of the watched
POE::Session.  If the session posts "irc_001", then
Reflex::POE::Session will emit "irc_001", and so on.

Reflex::POE::Session's "args" parameter will contain all of the POE
event's paramters, from ARG0 through the end of the parameter list.
They will be mapped to Reflex paramters "0" through the last index.

Assume that this POE post() call invokes this Reflex callback() via
Refex::POE::Session:

	$kernel->post( event => qw(one one two three five) );

	...;

	sub callback {
		my ($self, $args) = @_;
		print(
			"$args->{0}\n",
			"$args->{1}\n",
			"$args->{2}\n",
			"$args->{3}\n",
			"$args->{4}\n",
		);
	}

The callback will print five lines:

	one
	one
	two
	three
	five

=head1 CAVEATS

Reflex::POE::Session will take note of every event sent by the
session, although it won't try to deliver ones that haven't been
registered with the callback object.  However, the act of filtering
these events out is more overhead than simply not registering interest
in the first place.  A later version will be more optimal.

Reflex::POE::Wheel provides a way to map parameters to symbolic names.
Reflex::POE::Session may also provide a similar mechanism in the
future, obsoleting the parameter numbers.

=head1 SEE ALSO

L<Moose::Manual::Concepts>

L<Reflex>
L<Reflex::POE::Event>
L<Reflex::POE::Postback>
L<Reflex::POE::Wheel::Run>
L<Reflex::POE::Wheel>

L<Reflex/ACKNOWLEDGEMENTS>
L<Reflex/ASSISTANCE>
L<Reflex/AUTHORS>
L<Reflex/BUGS>
L<Reflex/BUGS>
L<Reflex/CONTRIBUTORS>
L<Reflex/COPYRIGHT>
L<Reflex/LICENSE>
L<Reflex/TODO>

=cut
