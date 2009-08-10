#!/usr/bin/env perl

# An object's emitted events can also trigger methods in the subclass.
# This example creates a UDP rot13 server using inheritance rather
# than the composition archtectures in past examples.

{
	package UdpEchoPeer;
	use Moose;
	extends 'UdpPeer';

	sub on_my_datagram {
		my ($self, $args) = @_;
		my $data = $args->{datagram};

		if ($data =~ /^\s*shutdown\s*$/) {
			$self->destruct();
			return;
		}

		$self->send(
			datagram    => $data,
			remote_addr => $args->{remote_addr},
		);
	}

	sub on_my_error {
		my ($self, $args) = @_;
		warn "$args->{op} error $args->{errnum}: $args->{errstr}";
		$self->destruct();
	}
}

my $peer = UdpEchoPeer->new( port => 12345 );
POE::Kernel->run();
exit;

#
#sub _handle_input :Handler {
#	my ($self, $args) = @_;
#
#	my $req_socket;
#
#	if (defined $remote_address) {
#		req->emit(
#			type              => "datagram",
#			args              => {
#				datagram        => $datagram,
#				remote_address  => $remote_address,
#			},
#		);
#	}
#	else {
#		req->emit(
#			type      => "recv_error",
#			args      => {
#				errnum  => $!+0,
#				errstr  => "$!",
#			},
#		);
#	}
#}
#
#=head2 send datagram => SCALAR, remote_address => ADDRESS
#
#Send a datagram to a remote address.  Usually called via recall() to
#respond to a datagram emitted by the Receiver.
#
#=cut
#
#sub send :Handler {
#	my ($self, $args) = @_;
#
#	my $req_socket;
#	return if send(
#		$req_socket,
#		$args->{datagram},
#		0,
#		$args->{remote_address},
#	) == length($args->{datagram});
#
#	req->emit(
#		type      => "send_error",
#		args      => {
#			errnum  => $!+0,
#			errstr  => "$!",
#		},
#	);
#}
#
#1;
#
#=head1 PUBLIC RESPONSES
#
#Here's what POE::Stage::Resolver will send back.
#
#=head2 "datagram" (datagram, remote_address)
#
#POE::Stage::Receiver emits a "datagram" message whenever it
#successfully recv()s a datagram from some remote peer.  The datagram
#message includes two parameters: "datagram" contains the received
#data, and "remote_address" contains the address that sent the
#datagram.
#
#Both parameters can be passed back to the POE::Stage::Receiver's
#send() method, as is done in the SYNOPSIS.
#
#	sub on_datagram {
#		my ($arg_datagram, $arg_remote_address);
#		my $output = function_of($arg_datagram);
#		my $req->recall(
#			method => "send",
#			args => {
#				remote_address => $arg_remote_address,
#				datagram => $output,
#			}
#		);
#	}
#
#=head2 "recv_error" (errnum, errstr)
#
#The stage encountered an error receiving from a peer.  "errnum" is the
#numeric form of $! after recv() failed.  "errstr" is the error's
#string form.
#
#	sub on_recv_error {
#		goto &on_send_error;
#	}
#
#=head2 "send_error" (errnum, errstr)
#
#The stage encountered an error receiving from a peer.  "errnum" is the
#numeric form of $! after send() failed.  "errstr" is the error's
#string form.
#
#	sub on_send_error {
#		my ($arg_errnum, $arg_errstr);
#		warn "Error $arg_errnum : $arg_errstr.  Shutting down.\n";
#		my $req_receiver = undef;
#	}
#
#=head1 BUGS
#
#See L<http://thirdlobe.com/projects/poe-stage/report/1> for known
#issues.  See L<http://thirdlobe.com/projects/poe-stage/newticket> to
#report one.
#
#POE::Stage is too young for production use.  For example, its syntax
#is still changing.  You probably know what you don't like, or what you
#need that isn't included, so consider fixing or adding that, or at
#least discussing it with the people on POE's mailing list or IRC
#channel.  Your feedback and contributions will bring POE::Stage closer
#to usability.  We appreciate it.
#
#=head1 SEE ALSO
#
#L<POE::Stage> and L<POE::Request>.  The examples/udp-peer.perl program
#in POE::Stage's distribution.
#
#=head1 AUTHORS
#
#Rocco Caputo <rcaputo@cpan.org>.
#
#=head1 LICENSE
#
#POE::Stage::Receiver is Copyright 2005-2006 by Rocco Caputo.  All rights
#are reserved.  You may use, modify, and/or distribute this module
#under the same terms as Perl itself.
#
#=cut
