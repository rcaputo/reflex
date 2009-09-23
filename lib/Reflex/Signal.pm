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
		my ($session_id, $stage_rec) = each %{$session_watchers{$signal_name}}
	) {
		foreach my $stage (values %$stage_rec) {
			$stage->emit(
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

no Moose;
__PACKAGE__->meta()->make_immutable();

1;

__END__

=head1 NAME

Reflex::Signal - Generic signal observer and base class for specific ones.

=head1 SYNOPSIS

TODO - Sorry, not yet.  This class works (see the source for
Reflex::PID, which extends it), but the API is not firm.

=head1 DESCRIPTION

Reflex::Signal is a generig signal observer.  Objects may use it to be
notified when the OS sends signals.  It may also be extended to handle
nuanced semantics of more specific signals.

TODO - Complete the API.

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
