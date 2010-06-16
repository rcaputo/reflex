package Reflex::Signal;

use Moose;
extends qw(Reflex::Object);
use Scalar::Util qw(weaken);

# A session may only watch a distinct signal once.
# So we must map each distinct signal to all the interested objects.

my %session_watchers;
my %signal_param_names;

has name => (
	isa     => 'Str|Undef',
	is      => 'rw',
	default => 'TERM',
);

sub _register_signal_params {
	my ($class, @names) = @_;
	$signal_param_names{$class->meta->get_attribute("name")->default()} = \@names;
}

sub BUILD {
	my $self = shift;

	# Register this object with that signal.
	$session_watchers{$self->name()}->{$self->session_id()}->{$self} = $self;
	weaken $session_watchers{$self->name()}->{$self->session_id()}->{$self};

	if (
		(
			scalar keys
			%{$session_watchers{$self->name()}->{$self->session_id()}}
		) == 1
	) {
		$self->start_watching();
	}
}

sub start_watching {
	my $self = shift;
	return unless $self->call_gate("start_watching");
	$POE::Kernel::poe_kernel->sig($self->name(), "signal_happened");
}

sub stop_watching {
	my $self = shift;
	return unless $self->call_gate("stop_watching");
	$POE::Kernel::poe_kernel->sig($self->name(), undef);
	$self->name(undef);
}

sub _deliver {
	my ($class, $signal_name, @signal_args) = @_;

	# If nobody's watching us, then why did we do it in the road?
	return unless exists $session_watchers{$signal_name};

	# Calculate the event arguments based on the signal name.
	my %event_args = ( name => $signal_name );
	if (exists $signal_param_names{$signal_name}) {
		my $i = 0;
		%event_args = (
			map { $_ => $signal_args[$i++] }
			@{$signal_param_names{$signal_name}}
		);
	}

	# Deliver the signal.

	while (
		my ($session_id, $object_rec) = each %{$session_watchers{$signal_name}}
	) {
		foreach my $object (values %$object_rec) {
			$object->emit(
				event => 'signal',
				args  => \%event_args,
			);
		}
	}
}

sub DEMOLISH {
	my $self = shift;

	return unless defined $self->name();

	my $sw = $session_watchers{$self->name()}->{$self->session_id()};
	delete $sw->{$self};

	unless (scalar keys %$sw) {
		delete $session_watchers{$self->name()};

		delete $session_watchers{$self->name()} unless (
			scalar keys %{$session_watchers{$self->name()}}
		);

		$self->stop_watching();
	}
}

1;

__END__

=head1 NAME

Reflex::Signal - Generic signal watcher and base class for specific ones.

=head1 SYNOPSIS

As a callback:

	use Reflex::Signal;
	use Reflex::Callbacks qw(cb_coderef);

	my $usr1 = Reflex::Signal->new(
		name      => "USR1",
		on_signal => cb_coderef { print "Got SIGUSR1.\n" },
	);

As a promise:

	my $usr2 = Reflex::Signal->new( name => "USR2" );
	while ($usr2->next()) {
		print "Got SIGUSR2.\n";
	}

May also be used with watchers, and Reflex::Trait::Observed, but
those use cases aren't shown here.

=head1 DESCRIPTION

Reflex::Signal is a general signal watcher.  It may be used to notify
programs when they are sent a signal via kill.

=head2 Public Attributes

=head3 name

"name" defines the name (or number) of an interesting signal.
The Reflex::Signal object will emit events when it detects that the
process has been given that signal.

=head2 Public Methods

None at this time.  Destroy the object to stop it.

=head2 Public Events

Reflex::Signal and its subclasses emit just one event: "signal".
Generic signals have no additional information, but specific ones may.
For example, Reflex::PID (SIGCHLD) includes a process ID and
information about its exit.

=head1 SEE ALSO

L<Moose::Manual::Concepts>

L<Reflex>
L<Reflex::PID>
L<Reflex::POE::Wheel::Run>

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
