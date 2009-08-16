package Signal;

use Moose;
extends qw(Stage);
use Scalar::Util qw(weaken);

# A session may only watch a distinct signal once.
# So we must map each distinct signal to all the interested objects.

my %session_watchers;

has name => (
	isa     => 'Str|Undef',
	is      => 'rw',
	default => 'TERM',
);

sub event_param_names {
	return [ ];
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

sub DESTROY {
	my $self = shift;

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

sub start_watching {
	my $self = shift;

	return $POE::Kernel::poe_kernel->call(
		$self->session_id(), "call_gate", $self, "start_watching", @_
	) if (
		$self->session_id() ne $POE::Kernel::poe_kernel->get_active_session()->ID()
	);

	$POE::Kernel::poe_kernel->sig($self->name(), "signal_happened");
}

sub stop_watching {
	my $self = shift;

	return $POE::Kernel::poe_kernel->call(
		$self->session_id(), "call_gate", $self, "stop_watching", @_
	) if (
		$self->session_id() ne $POE::Kernel::poe_kernel->get_active_session()->ID()
	);

	$POE::Kernel::poe_kernel->sig($self->name(), undef);
	$self->name(undef);
}

sub _deliver {
	my ($class, $signal_name, @signal_args) = @_;

	# If nobody's watching us, then why did we do it in the road?
	return unless exists $session_watchers{$signal_name};

	# Deliver the signal.

	while (
		my ($session_id, $stage_rec) = each %{$session_watchers{$signal_name}}
	) {
		foreach my $stage (values %$stage_rec) {

			# TODO - All stages here theoretically have the same class, and
			# therefore the same parameters.  Don't recalculate %args.
			my $i = 0;
			my $param_names = $stage->event_param_names();
			my %event_args  = map { $_ => $signal_args[$i++] } @$param_names;
			$event_args{name} = $signal_name;

			$stage->emit(
				event => 'signal',
				args  => \%event_args,
			);
		}
	}
}

sub DEMOLISH {
	my $self = shift;
	$self->stop_watching() if defined $self->name();
}

1;
