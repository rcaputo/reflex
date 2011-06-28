package Proxy;
# vim: ts=2 sw=2 noexpandtab

use Moose;
extends "Reflex::Base";
use Reflex::Callbacks "make_null_handler";

has client => ( is => "rw", isa => "FileHandle", required => 1 );
has server => ( is => "rw", isa => "FileHandle", required => 1 );

has active => ( is => "ro", isa => "Bool", default => 1 );

make_null_handler("on_client_closed");
make_null_handler("on_server_closed");
make_null_handler("on_client_error");
make_null_handler("on_server_error");

with "Reflex::Role::Streaming" => {
  att_active => "active",
  att_handle => "client",
};

with "Reflex::Role::Streaming" => {
  att_active => "active",
  att_handle => "server",
};

sub on_client_data {
  my ($self, $arg) = @_;
  $self->put_server($arg->{data});
}

sub on_server_data {
  my ($self, $arg) = @_;
  $self->put_client($arg->{data});
}

1;
