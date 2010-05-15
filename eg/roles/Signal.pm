package Signal;
use MoseX::Role::Parameterized;

parameter signal => (
	isa => 'Str',
	required  => 1,
);

parameter cb_signal => (
	isa       => 'Str',
	default   => sub {
		my $self = shift;
		"on_" . lc($self->signal()) . "_caught";
	},
	lazy      => 1,
);

role {
	after BUILD => sub {
		# ... register the handler
	};

	method stop => sub {
		# ... deregister the signal handler
	};

	after DEMOLISH => sub {
		# ... make sure the signal is not watched anymore
	};
};

1;
