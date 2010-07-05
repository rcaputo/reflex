package Reflex::SigCatcher;

use Moose;
extends 'Reflex::Base';

has signal => (
	is        => 'ro',
	isa       => 'Str',
	required  => 1,
);

has active => (
	is      => 'ro',
	isa     => 'Bool',
	default => 1,
);

with 'Reflex::Role::SigCatcher' => {
	signal        => 'signal',
	active        => 'active',
	cb_signal     => 'on_signal',
	method_start  => 'start',
	method_stop   => 'stop',
	method_pause  => 'pause',
	method_resume => 'resume',
};

1;
