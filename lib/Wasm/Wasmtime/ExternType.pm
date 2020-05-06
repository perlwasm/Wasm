package Wasm::Wasmtime::ExternType;

use strict;
use warnings;
use Wasm::Wasmtime::FFI;
use Wasm::Wasmtime::FuncType;
use Wasm::Wasmtime::GlobalType;
use Wasm::Wasmtime::TableType;
use Wasm::Wasmtime::MemoryType;

# ABSTRACT: Wasmtime extern type class
# VERSION

=head1 DESCRIPTION

This is a private class.  The C<.pm> file for it may be removed in the future.

=cut

$ffi_prefix = 'wasm_externtype_';

$ffi->attach( [ kind => '_kind' ] => ['opaque'] => 'uint8' );

my @cast = map {
  $ffi->function( "as_$_" => ['opaque'] => "wasm_${_}_t" )->sub_ref
} qw( functype globaltype tabletype memorytype );


$ffi->custom_type('wasm_externtype_t' => {
  native_type => 'opaque',
  native_to_perl => sub {
    my $externtype = shift;
    Carp::croak("externtype error") unless defined $externtype;
    my $kind = _kind($externtype);
    $cast[$kind]->($externtype);
  },
});

1;
