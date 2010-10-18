package Reflex::Role::InStreaming;
use Reflex::Role;

attribute_parameter handle      => "handle";

callback_parameter  cb_data     => qw( on handle data );
callback_parameter  cb_error    => qw( on handle error );
callback_parameter  cb_closed   => qw( on handle closed );

callback_parameter  ev_error    => qw( _ handle error );

method_parameter    method_stop => qw( stop handle _ );

role {
	my $p = shift;

	my $h           = $p->handle();
	my $cb_error    = $p->cb_error();
	my $method_read = "_on_${h}_readable";

	with 'Reflex::Role::Collectible';

	method_emit_and_stop $cb_error => $p->ev_error();

	with 'Reflex::Role::Reading' => {
		handle      => $h,
		cb_data     => $p->cb_data(),
		cb_error    => $cb_error,
		cb_closed   => $p->cb_closed(),
		method_read => $method_read,
	};

	with 'Reflex::Role::Readable' => {
		handle      => $h,
		active      => 1,
		cb_ready    => $method_read,
		method_stop => $p->method_stop(),
	};
};

1;

