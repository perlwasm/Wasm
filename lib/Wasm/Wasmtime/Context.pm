package Wasm::Wasmtime::Context;

use strict;
use warnings;
use 5.008004;
use Wasm::Wasmtime::FFI;

# ABSTRACT: Wasmtime context class
# VERSION

$ffi_prefix = 'wasmtime_context_';
$ffi->load_custom_type('::PtrObject' => 'wasmtime_context_t' => __PACKAGE__);

=head1 SYNOPSIS

# TODO

=head1 DESCRIPTION

TODO

=head1 METHODS

=head2 get_data

TODO

=head2 set_data

TODO

=head2 gc

Garbage collects C<externref>s that are used by this context. Any
C<externref>s that are discovered to be unreachable by other code or objects
will have their finalizers run.

=cut

if(_ver ne '0.27.0')
{
  $ffi->attach( gc => ['wasmtime_context_t'] => 'void' );
}

=head2 add_fuel

TODO

=head2 fuel_consumed

TODO

=head2 set_wasi

TODO

=cut

# TODO: class for wasmtime_interrupt_handler

1;
