package AsyncAwhileRole;
use Reflex::Role;
use Reflex::Timer;
use Reflex::Callbacks qw(cb_method);

attribute_parameter name    => "name";
attribute_parameter awhile  => "awhile";
callback_parameter  cb      => qw( on name done );

role {
	my $role_param = shift;

	my $role_name = $role_param->name();
	my $cb_done   = $role_param->cb();
	my $awhile    = $role_param->awhile();

	my $timer_member = "_${role_name}_timer";

	has $timer_member => ( is => 'rw', isa => 'Reflex::Timer' );

	method_emit $cb_done => "done";

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
};

1;
