package EventyRole;
use Moose::Role;

sub post {
	my ($self, @etc) = @_;
	warn "$self->post(@etc)\n";
}

no Moose;

1;
