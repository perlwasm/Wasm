package Wasm::Func;

use strict;
use warnings;

# ABSTRACT: Interface to WebAssembly Memory
# VERSION

=head1 SYNOPSIS

Call Wasm from Perl:

# EXAMPLE: examples/synopsis/func3.pl

Call Perl from Wasm:

# EXAMPLE: examples/synopsis/func4.pl

=head1 DESCRIPTION

This documents the interface to functions for L<Wasm>.
Each function exported from WebAssembly is automatically
imported into Perl space as a Perl subroutine.  Wasm modules
can import Perl subroutines using their standard import process.

=head1 SEE ALSO

=over 4

=item L<Wasm>

=back

=cut

1;
