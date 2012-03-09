package Reflex::Filehandle;
# vim: ts=2 sw=2 noexpandtab

use Moose;
extends 'Reflex::Base';
use Reflex::Callbacks qw(make_emitter);
use Carp qw(croak);

has descriptor => ( is => 'rw', isa => 'Maybe[Int]', default => undef );

has handle => (
  is      => 'rw',
  isa     => 'FileHandle',
  lazy    => 1,
  default => sub {
    my $self = shift();
    my $fd = $self->descriptor();
    croak "Reflex::Filehandle must have a descriptor handle" unless (
      defined $fd
    );

    open my($fh), "+<&=$fd" or croak "can't dup fd $fd: $!";

    return $fh;
  }
);

has rd => ( is => 'ro', isa => 'Bool', default => 0 );
has wr => ( is => 'ro', isa => 'Bool', default => 0 );

with 'Reflex::Role::Readable' => {
  att_handle    => 'handle',
  att_active    => 'rd',
  cb_ready      => make_emitter(on_readable => 'readable'),
  method_pause  => 'pause_rd',
  method_resume => 'resume_rd',
  method_stop   => 'stop_rd',
};

with 'Reflex::Role::Writable' => {
  att_handle    => 'handle',
  att_active    => 'wr',
  cb_ready      => make_emitter(on_writable => 'writable'),
  method_pause  => 'pause_wr',
  method_resume => 'resume_wr',
  method_stop   => 'stop_wr',
};

1;
