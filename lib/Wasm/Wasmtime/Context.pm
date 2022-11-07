package Wasm::Wasmtime::Context;

use strict;
use warnings;
use 5.008004;
use Wasm::Wasmtime::FFI;
use Wasm::Wasmtime::Store;

# ABSTRACT: Wasmtime context class
# VERSION

$ffi_prefix = 'wasmtime_context_';

=head1 SYNOPSIS

# EXAMPLE: examples/synopsis/context.pl

=head1 DESCRIPTION

A wasmtime context object.

=head1 METHODS

=head2 gc

Garbage collects C<externref>s that are used by this context. Any
C<externref>s that are discovered to be unreachable by other code or objects
will have their finalizers run.

=cut

if(_ver ne '0.27.0')
{
  $ffi->attach( gc => ['wasmtime_context_t'] );
}
else
{
  $ffi->attach( [ wasmtime_store_gc => 'gc' ] => ['wasm_store_t'] => sub {
    my($xsub, $self) = @_;
    $xsub->($self->{store});
  });
}

1;
