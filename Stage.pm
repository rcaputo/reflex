package Stage;

use Moose;
with 'StageRole';

# Composes the StageRole role into a class.
# Does nothing of its own.

no Moose;
__PACKAGE__->meta()->make_immutable();

1;
