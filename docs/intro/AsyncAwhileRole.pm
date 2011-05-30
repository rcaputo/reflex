package AsyncAwhileRole;
use Reflex::Role;
use Reflex::Interval;
use Reflex::Callbacks qw(cb_method);

attribute_parameter att_awhile => "awhile";
attribute_parameter att_name   => "name";
callback_parameter  cb         => qw( on att_name done );

role {
	my $role_param = shift;

	my $att_awhile = $role_param->att_awhile();
	my $att_name   = $role_param->att_name();
	my $cb_done    = $role_param->cb();

	requires $att_awhile, $att_name, $cb_done;

	my $timer_member = "_${role_name}_timer";

	has $timer_member => ( is => 'rw', isa => 'Reflex::Interval' );

	sub BUILD {}

	after BUILD => sub {
		my $self = shift;
		$self->$timer_member(
			Reflex::Interval->new(
				auto_repeat => 0,
				interval    => $self->$awhile(),
				on_tick     => cb_method($self, $cb_done),
			)
		);
	};
};

1;
