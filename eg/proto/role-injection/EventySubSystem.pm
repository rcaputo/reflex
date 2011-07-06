package EventySubSystem;
use Moose::Role;

sub post {
	my ($self, @etc) = @_;
	warn "$self->post(@etc)\n";
}

Moose::Util::apply_all_roles(BaseClass => __PACKAGE__);

no Moose;

1;
