package AsyncAwhileRole;
use MooseX::Role::Parameterized;
use Reflex::Util::Methods qw(method_name emit_an_event);
use Reflex::Timer;
use Reflex::Callbacks qw(cb_method);

parameter name    => ( isa => 'Str', default => 'name' );
parameter awhile  => ( isa => 'Str', default => 'awhile' );
parameter cb      => method_name("on", "name", "done");

role {
	my $role_param = shift;

	my $role_name = $role_param->name();
	my $cb_done   = $role_param->cb();
	my $awhile    = $role_param->awhile();

	my $timer_member = "_${role_name}_timer";

	has $timer_member => ( is => 'rw', isa => 'Reflex::Timer' );

	sub BUILD {}

	after BUILD => sub {
		my $self = shift;
		$self->$timer_member(
			Reflex::Timer->new(
				auto_repeat => 0,
				interval    => $self->$awhile(),
				on_tick     => cb_method($self, $cb_done),
			)
		);
	};

	method $cb_done => emit_an_event("done");
};

1;
