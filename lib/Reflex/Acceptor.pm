package Reflex::Acceptor;

use Moose;
extends 'Reflex::Base';

has listener => (
	is        => 'rw',
	isa       => 'FileHandle',
	required  => 1
);

with 'Reflex::Role::Accepting' => {
	listener      => 'listener',
	cb_accept     => 'on_accept',
	cb_error      => 'on_error',
	method_pause  => 'pause',
	method_resume => 'resume',
	method_stop   => 'stop',
};

1;
