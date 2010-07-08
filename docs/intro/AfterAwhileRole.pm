package AfterAwhileRole;
use MooseX::Role::Parameterized;
use Reflex::Util::Methods qw(method_name emit_an_event);

parameter name    => ( isa => 'Str', default => 'name' );
parameter awhile  => ( isa => 'Str', default => 'awhile' );
parameter cb      => method_name("on", "name", "done");

role {
	my $role_param = shift;

	my $role_name = $role_param->name();
	my $cb_done   = $role_param->cb();
	my $awhile    = $role_param->awhile();

	sub BUILD {}

	after BUILD => sub {
		my $self = shift;
		sleep($self->$awhile());
		$self->$cb_done();
	};

	method $cb_done => emit_an_event("done");
};

1;
