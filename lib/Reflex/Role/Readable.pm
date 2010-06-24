package Reflex::Role::Readable;
use MooseX::Role::Parameterized;
use Reflex::Util::Methods qw(emit_an_event);

# TODO - Reflex::Role::Readable and Writable are nearly identical.
# Can they be abstracted further?

use Scalar::Util qw(weaken);

parameter handle => (
	isa     => 'Str',
	default => 'handle',
);

parameter active => (
	isa     => 'Bool',
	default => 1,
);

parameter cb_ready => (
	isa       => 'Str',
	default   => sub {
		my $self = shift;
		"on_" . $self->handle() . "_readable";
	},
	lazy      => 1,
);

parameter method_pause => (
	isa       => 'Str',
	default   => sub {
		my $self = shift;
		"pause_" . $self->handle() . "_readable";
	},
	lazy      => 1,
);

parameter method_resume => (
	isa       => 'Str',
	default   => sub {
		my $self = shift;
		"resume_" . $self->handle() . "_readable";
	},
	lazy      => 1,
);

role {
	my $p = shift;

	my $h = $p->handle();
	my $active = $p->active();

	my $cb_name       = $p->cb_ready();
	my $pause_name    = $p->method_pause();
	my $resume_name   = $p->method_resume();
	my $setup_name    = "_setup_${h}_readable";

	method $setup_name => sub {
		my ($self, $arg) = @_;

		# Must be run in the right POE session.
		return unless $self->call_gate($setup_name, $arg);

		my $envelope = [ $self ];
		weaken $envelope->[0];
		$POE::Kernel::poe_kernel->select_read(
			$self->$h(), 'select_ready', $envelope, $cb_name,
		);

		return if $active;

		$POE::Kernel::poe_kernel->select_pause_read($self->$h());
	};

	method $pause_name => sub {
		my $self = shift;
		$POE::Kernel::poe_kernel->select_pause_read($self->$h());
	};

	method $resume_name => sub {
		my $self = shift;
		$POE::Kernel::poe_kernel->select_resume_read($self->$h());
	};

	after BUILD => sub {
		my ($self, $arg) = @_;
		$self->$setup_name($arg);
	};

	# Turn off watcher during destruction.
	after DEMOLISH => sub {
		my $self = shift;
		$POE::Kernel::poe_kernel->select_read($self->h(), undef);
	};

	# Part of the POE/Reflex contract.
	method deliver => sub {
		my ($self, $handle, $cb_member) = @_;
		$self->$cb_member( { handle => $handle, } );
	};

	# Default callbacks that re-emit their parameters.
	method $cb_name => emit_an_event("${h}_readable");
};

1;

__END__

=head1 NAME

Reflex::Role::Readable - add readable-watching behavior to a class

=head1 SYNOPSIS

	use Moose;

	has socket => ( is => 'rw', isa => 'FileHandle', required => 1 );

	with 'Reflex::Role::Readable' => {
		handle   => 'socket',
		cb_ready => 'on_socket_readable',
		active   => 1,
	};

	sub on_socket_readable {
		my ($self, $arg) = @_;
		print "Data is ready on socket $arg->{handle}.\n";
		$self->pause_socket_readabe();
	}

=head1 DESCRIPTION

Reflex::Role::Readable is a Moose parameterized role that adds
readable-watching behavior for Reflex-based classes.  In the SYNOPSIS,
a filehandle named "socket" is watched for readability.  The method
on_socket_readable() is called when data becomes available.

TODO - Explain the difference between role-based and object-based
composition.

=head2 Required Role Parameters

=head3 handle

The C<handle> parameter must contain the name of the attribute that
holds the handle to watch.  The name indirection allows the role to
generate unique methods by default.  For example, a handle named "XYZ"
would generates these methods by default:

	cb_ready      => "on_XYZ_readable",
	method_pause  => "pause_XYZ_readable",
	method_resume => "resume_XYZ_readable",

This naming convention allows the role to be used for more than one
handle in the same class.  Each handle will have its own name, and the
mixed in methods associated with them will also be unique.

=head2 Optional Role Parameters

=head3 active

C<active> specifies whether the Reflex::Role::Readable watcher should
be enabled when it's initialized.  All Reflex watchers are enabled by
default.  Set it to a false value, preferably 0, to initialize the
watcher in an inactive or paused mode.

Readability watchers may be paused and resumed.  See C<method_pause>
and C<method_resume> for ways to override the default method names.

=head3 cb_ready

C<cb_ready> names the $self method that will be called whenever
C<handle> has data to be read.  By default, it's the catenation of
"on_", the C<handle> name, and "_readable".  A handle named "XYZ" will
by default trigger on_XYZ_readable() callbacks.

	handle => "socket",  # on_socket_readable()
	handle => "XYZ",     # on_XYZ_readable()

All Reflex parameterized role callbacks are invoked with two
parameters: $self and an anonymous hashref of named values specific to
the callback.  C<cb_ready> callbacks include a single named value,
C<handle>, that contains the filehandle from which has become ready
for reading.

C<handle> is the handle itself, not the handle attribute's name.

=head3 method_pause

C<method_pause> sets the name of the method that may be used to pause
the watcher.  It is "pause_${handle}_readable" by default.

=head3 method_resume

C<method_resume> may be used to resume paused readability watchers, or
to activate them if they are started in an inactive state.

=head1 EXAMPLES

TODO - I'm sure there are some.

=head1 SEE ALSO

L<Reflex>
L<Reflex::Role::Writable>
L<Reflex::Role::Streaming>

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
