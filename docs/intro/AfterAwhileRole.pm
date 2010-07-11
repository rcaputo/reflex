package AfterAwhileRole;
use Reflex::Role;

attribute_parameter name    => "name";
attribute_parameter awhile  => "awhile";
callback_parameter  cb      => qw( on name done );

role {
	my $role_param = shift;

	my $cb_done   = $role_param->cb();
	my $awhile    = $role_param->awhile();

	method_emit $cb_done => "done";

	sub BUILD {}

	after BUILD => sub {
		my $self = shift;
		sleep($self->$awhile());
		$self->$cb_done();
	};
};

1;
