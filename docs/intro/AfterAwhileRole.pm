package AfterAwhileRole;
use Reflex::Role;

# TODO - Is att_name really needed?
attribute_parameter att_awhile => "awhile";
attribute_parameter att_name   => "name";
callback_parameter  cb         => qw( on att_name done );

role {
	my $role_param = shift;

	my $att_awhile = $role_param->att_awhile();
	my $cb_done    = $role_param->cb();

	requires $att_awhile, $p->att_name(), $cb_done;

	sub BUILD {}
	after BUILD => sub {
		my $self = shift;
		sleep($self->$att_awhile());
		$self->$cb_done();
	};
};

1;
