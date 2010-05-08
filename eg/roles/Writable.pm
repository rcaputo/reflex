package Writable;
use MooseX::Role::Parameterized;

die die die "doesn't work, see source";

# TODO - Figure out how to subclass parameterized roles and override
# attributes of their parameters.  For instance, Writable only differs
# from Readable in the default parameters!

with 'Readable';

parameter '+knob_suffix' => ( default => '_wr' );
# TODO - Etc.

# Don't define anything; use what Readable gives us?
role { };

1;
