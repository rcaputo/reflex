package PoCoEvent;
# vim: ts=2 sw=2 noexpandtab

# A component that accepts an event name to which return messages are
# posted.  In this case, the component builds a postback for the
# calling session, which makes a more complex but satisfying test
# case.
#
# TODO - Refactor into a base class and subclasses.  This is only a
# couple lines different from PoCoPostback.

use warnings;
use strict;
use POE;

sub new {
	my $class = shift;

	my $self = bless { }, $class;

	my $result = 'aaaaaaaa';

	POE::Session->create(
		inline_states => {
			_start => sub {
				# Set an alias based on the object that owns us.
				$_[HEAP]{alias} = "$self";
				$_[KERNEL]->alias_set("$self");
			},
			shutdown => sub {
				# Shutdown is triggered by the object DESTROY.
				# Remove the alias, and gracefully exit when all pending
				# timers are done.
				$_[KERNEL]->alias_remove($_[HEAP]{alias});
			},
			request => sub {
				# Handle a request.  Feign some work.
				my $event = $_[ARG0];
				my $postback = $_[SENDER]->postback($event);
				$_[KERNEL]->delay_add(
					work_done => rand(3) => $postback => $result++
				);
			},
			work_done => sub {
				# When the work is done, post back a result.
				my ($postback, $result) = @_[ARG0, ARG1];
				$postback->($result);
			},
		},
	);

	return $self;
}

# Clean up the session on destruction.
sub DESTROY {
	my $self = shift;
	$poe_kernel->call("$self", "shutdown");
}

# Convenience method.  Hide POE::Kernel->post.
sub request {
	my ($self, $postback) = @_;
	$poe_kernel->post("$self", "request", $postback);
}

1;
