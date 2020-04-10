package Wasm::Wasmtime;

use strict;
use warnings;
use Wasm::Wasmtime::Config;
use Wasm::Wasmtime::Engine;
use Wasm::Wasmtime::ExportType;
use Wasm::Wasmtime::Extern;
use Wasm::Wasmtime::ExternType;
use Wasm::Wasmtime::Func;
use Wasm::Wasmtime::FuncType;
use Wasm::Wasmtime::Instance;
use Wasm::Wasmtime::Module;
use Wasm::Wasmtime::Store;
use Wasm::Wasmtime::Trap;
use Wasm::Wasmtime::ValType;
use Wasm::Wasmtime::WasiConfig;
use Wasm::Wasmtime::WasiInstance;

# ABSTRACT: Perl interface to Wasmtime
# VERSION

=head1 SYNOPSIS

# EXAMPLE: examples/synopsis/wasmtime.pl

=head1 DESCRIPTION

B<WARNING>: WebAssembly and Wasmtime are a moving target and the interface for these modules
is under active development.  Use with caution.

This module pre-loads all the relevant Wasmtime modules so that you can just start using the
appropriate classes.

If you are just getting your feet wet with WebAssembly and Perl then you probably want to
take a look at L<Wasm>, which is a simple interface that automatically imports functions
from Wasm space into Perl space.

=head1 SEE ALSO

=over 4

=item L<Wasm>

=item L<Wasm::Wasmtime::Module>

=item L<Wasm::Wasmtime::Instance>

=item L<Wasm::Wasmtime::Func>

=item L<Wasm::Wasmtime::Wat2Wasm>

=back

=cut

1;
