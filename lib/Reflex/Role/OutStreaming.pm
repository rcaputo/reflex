package Reflex::Role::OutStreaming;
use Reflex::Role;

attribute_parameter handle      => "handle";

callback_parameter  cb_data     => qw( on handle data );
callback_parameter  cb_error    => qw( on handle error );
callback_parameter  cb_closed   => qw( on handle closed );

callback_parameter  ev_error    => qw( ev handle error );

method_parameter    method_put  => qw( put handle _ );
method_parameter    method_stop => qw( stop handle _ );

role {
	my $p = shift;

	my $h           = $p->handle();
	my $cb_error    = $p->cb_error();
	my $method_put  = $p->method_put();

	my $method_writable = "_on_${h}_writable";
	my $internal_flush  = "_do_${h}_flush";
	my $internal_put    = "_do_${h}_put";
	my $pause_writable  = "_pause_${h}_writable";
	my $resume_writable = "_resume_${h}_writable";

	with 'Reflex::Role::Collectible';

	method_emit_and_stop $cb_error => $p->ev_error();

	with 'Reflex::Role::Writing' => {
		handle      => $h,
		cb_error    => $cb_error,
		method_put  => $internal_put,
	};

	method $method_writable => sub {
		my ($self, $arg) = @_;

		my $octets_left = $self->$internal_flush();
		return if $octets_left;

		$self->$pause_writable($arg);
	};

	with 'Reflex::Role::Writable' => {
		handle      => $h,
		cb_ready    => $method_writable,
		method_pause => $pause_writable,
	};

	method $method_put => sub {
		my ($self, $arg) = @_;
		my $flush_status = $self->$internal_put($arg);
		return unless $flush_status;
		$self->$resume_writable(), return if $flush_status == 1;
	};
};

1;
