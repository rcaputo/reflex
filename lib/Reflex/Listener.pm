# A listen/accept server.

package Reflex::Listener;
use Moose;
extends 'Reflex::Handle';

has '+rd' => ( default => 1 );

sub on_handle_readable {
	my ($self, $args) = @_;

	my $peer = accept(my ($socket), $args->{handle});
	if ($peer) {
		$self->emit(
			event => "accepted",
			args  => {
				peer    => $peer,
				socket  => $socket,
			}
		);
		return;
	}

	$self->emit(
		event => "fail",
		args  => {
			peer    => undef,
			socket  => undef,
			errnum  => ($!+0),
			errstr  => "$!",
			errfun  => "accept",
		},
	);
}

1;
