package Wasm::Global;

use strict;
use warnings;

# ABSTRACT: Interface to Web Assembly Memory
# VERSION

=head1 SYNOPSIS

# EXAMPLE: examples/synopsis/global2.pl

=head1 DESCRIPTION

This class represents a global variable exported from a WebAssembly
module.  Each global variable exported from WebAssembly is automatically
imported into Perl space as a tied scalar, which allows you to get
and set the variable easily from Perl.

=head1 CAVEATS

Note that depending on the
storage of the global variable setting might be lossy and round-trip
isn't guaranteed.  For example for integer types, if you set a string
value it will be converted to an integer using the normal Perl string
to integer conversion, and when it comes back you will just have
the integer value.

=head1 SEE ALSO

=over 4

=item L<Wasm>

=back

=cut

1;
