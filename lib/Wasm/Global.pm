package Wasm::Global;

use strict;
use warnings;
use 5.008004;

# ABSTRACT: Interface to WebAssembly Memory
# VERSION

=head1 SYNOPSIS

Import globals into Perl from WebAssembly

# EXAMPLE: examples/synopsis/global2.pl

Import globals from Perl into WebAssembly

# EXAMPLE: examples/synopsis/global3.pl

=head1 DESCRIPTION

B<WARNING>: WebAssembly and Wasmtime are a moving target and the
interface for these modules is under active development.  Use with
caution.

This documents the interface to global variables for L<Wasm>.
Each global variable exported from WebAssembly is automatically
imported into Perl space as a tied scalar, which allows you to get
and set the variable easily from Perl.  Going the other way
requires a bit more boilerplate, but is almost as easy.  Using
the C<-global> option on the L<Wasm> module, you can define global
variables in Pure Perl modules that can be imported into WebAssembly
from Perl.

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
