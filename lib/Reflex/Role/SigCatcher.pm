package Reflex::Role::SigCatcher;
use MooseX::Role::Parameterized;
use Reflex::Util::Methods qw(method_name emit_an_event);

use Scalar::Util qw(weaken);

parameter signal => (
	isa       => 'Str',
	default   => 'signal',
);

parameter active => (
	isa       => 'Str',
	default   => 'active',
);

parameter cb_signal     => method_name("on", "signal", "caught");
parameter method_start  => method_name("start", "signal", undef);
parameter method_stop   => method_name("stop", "signal", undef);
parameter method_pause  => method_name("pause", "signal", undef);
parameter method_resume => method_name("resume", "signal", undef);

# A session may only watch a distinct signal once.
# So we must map each distinct signal to all the interested objects.
# This is class scoped data.
#
# TODO - We could put this closer to the POE::Session and obviate the
# need for the deliver() redirector.

my %callbacks;
my %signal_param_names;

sub _register_signal_params {
	my ($class, @names) = @_;
	$signal_param_names{$class->meta->get_attribute("signal")->default()} = \@names;
}

sub deliver {
	my ($class, $signal_name, @signal_args) = @_;

	# If nobody's watching us, then why did we do it in the road?
	# TODO - Diagnostic warning/error?
	return unless exists $callbacks{$signal_name};

	# Calculate the event arguments based on the signal name.
	my %event_args = ( signal => $signal_name );
	if (exists $signal_param_names{$signal_name}) {
		my $i = 0;
		%event_args = (
			map { $_ => $signal_args[$i++] }
			@{$signal_param_names{$signal_name}}
		);
	}

	# Deliver the signal.
	# TODO - map() magic to speed this up?

	foreach my $callback_recs (values %{$callbacks{$signal_name}}) {
		foreach my $callback_rec (values %$callback_recs) {
			my ($object, $method) = @$callback_rec;
			$object->$method(\%event_args);
		}
	}
}

# The role itself.

role {
	my $p = shift;

	my $signal        = $p->signal();
	my $active        = $p->active();
	my $cb_signal     = $p->cb_signal();

	my $method_start  = $p->method_start();
	my $method_stop   = $p->method_stop();
	my $method_pause  = $p->method_pause();
	my $method_resume = $p->method_resume();

	# Work around a Moose edge case.
	sub BUILD {};

	after BUILD => sub {
		return unless $active;
		shift()->$method_start();
		return;
	};

	method $method_start => sub {
		my $self = shift;

		my $sig_name = $self->$signal();

		# Register this object with that signal.
		$callbacks{$sig_name}->{$self->session_id()}->{$self} = [
			$self, $cb_signal
		];
		weaken $callbacks{$sig_name}->{$self->session_id()}->{$self}->[0];

		# First time this object is watching that signal?  Start the
		# watcher.  Otherwise, a watcher should already be going.

		return if (
			(scalar keys %{$callbacks{$sig_name}->{$self->session_id()}}) > 1
		);

		$self->$method_resume();
	};

	method $method_pause => sub {
		my $self = shift;

		# Be in the session associated with this object.
		return unless $self->call_gate($method_pause);

		$POE::Kernel::poe_kernel->sig($self->$signal(), undef);
	};

	method $method_resume => sub {
		my $self = shift;

		# Be in the session associated with this object.
		return unless $self->call_gate($method_resume);

		$POE::Kernel::poe_kernel->sig($self->$signal(), "signal_happened");
	};

	method $method_stop => sub {
		my $self = shift;

		my $sig_name = $self->$signal();

		# Unregister this object with that signal.
		my $sw = $callbacks{$sig_name}->{$self->session_id()};
		delete $sw->{$self};

		# Deactivate the signal watcher if this was the last object.
		unless (scalar keys %$sw) {
			delete $callbacks{$sig_name}->{$self->session_id()};

			delete $callbacks{$sig_name} unless (
				scalar keys %{$callbacks{$sig_name}}
			);

			$self->$method_pause();
		}
	};

	method $cb_signal => emit_an_event("signal");
};

__END__


sub stop_watching {
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
