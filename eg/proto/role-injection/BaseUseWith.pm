package BaseUseWith;
use Moose;

sub generic_helper {
	my ($self, @etc) = @_;
	warn "$self posted (@etc)";
}

sub import {
	my ($class, %args) = @_;

	return unless exists $args{with};

	my $args = $args{with};
	$args = [ $args ] unless ref($args);

	Moose::Util::apply_all_roles($class, @$args);

	return;
};

no Moose;

1;
