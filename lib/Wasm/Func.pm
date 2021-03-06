package Wasm::Func;

use strict;
use warnings;
use 5.008004;

# ABSTRACT: Interface to WebAssembly functions
# VERSION

=head1 SYNOPSIS

Call Wasm from Perl:

# EXAMPLE: examples/synopsis/func3.pl

Call Perl from Wasm:

# EXAMPLE: examples/synopsis/func4.pl

=head1 DESCRIPTION

B<WARNING>: WebAssembly and Wasmtime are a moving target and the
interface for these modules is under active development.  Use with
caution.

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
