package Reflex::Role::Readable;
# vim: ts=2 sw=2 noexpandtab

use Reflex::Role;

# TODO - Reflex::Role::Readable and Writable are nearly identical.
# Can they be abstracted further?  Possibly composed as parameterized
# instances of a common base role?

use Scalar::Util qw(weaken);

attribute_parameter att_handle    => "handle";
attribute_parameter att_active    => "active";
callback_parameter  cb_ready      => qw( on att_handle readable );
method_parameter    method_pause  => qw( pause att_handle readable );
method_parameter    method_resume => qw( resume att_handle readable );
method_parameter    method_stop   => qw( stop att_handle readable );

role {
	my $p = shift;

	my $att_active = $p->att_active();
	my $att_handle = $p->att_handle();
	my $cb_name    = $p->cb_ready();

	requires $att_active, $att_handle, $cb_name;

	my $setup_name = "_setup_${att_handle}_readable";

	method $setup_name => sub {
		my ($self, $arg) = @_;

		# Must be run in the right POE session.
		return unless $self->call_gate($setup_name, $arg);

		my $envelope = [ $self, $cb_name ];
		weaken $envelope->[0];
		$POE::Kernel::poe_kernel->select_read(
			$self->$att_handle(), 'select_ready', $envelope,
		);

		return if $self->$att_active();

		$POE::Kernel::poe_kernel->select_pause_read($self->$att_handle());
	};

	my $method_pause = $p->method_pause();
	method $method_pause => sub {
		my $self = shift;
		return unless $self->call_gate($method_pause);
		$POE::Kernel::poe_kernel->select_pause_read($self->$att_handle());
	};

	my $method_resume = $p->method_resume();
	method $p->method_resume => sub {
		my $self = shift;
		return unless $self->call_gate($method_resume);
		$POE::Kernel::poe_kernel->select_resume_read($self->$att_handle());
	};

	my $method_stop = $p->method_stop();
	method $method_stop => sub {
		my $self = shift;
		return unless $self->call_gate($method_stop);
		$POE::Kernel::poe_kernel->select_read($self->$att_handle(), undef);
	};

	# Work around a Moose edge case.
	sub BUILD {}

	after BUILD => sub {
		my ($self, $arg) = @_;
		$self->$setup_name($arg);
	};

	# Work around a Moose edge case.
	sub DEMOLISH {}

	# Turn off watcher during destruction.
	after DEMOLISH => sub {
		my $self = shift;
		$self->$method_stop();
	};
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
	method_stop   => "stop_XYZ_readable",

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

=head3 method_stop

C<method_stop> may be used to stop readability watchers.  These
watchers may not be restarted once they've been stopped.  If you want
to pause and resume watching, see C<method_pause> and
C<method_resume>.

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
