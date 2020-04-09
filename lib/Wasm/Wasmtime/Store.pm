package Wasm::Wasmtime::Store;

use strict;
use warnings;
use Wasm::Wasmtime::FFI;
use Wasm::Wasmtime::Engine;

# ABSTRACT: Wasmtime store class
# VERSION

$ffi_prefix = 'wasm_store_';
$ffi->type('opaque' => 'wasm_store_t');

$ffi->attach( new => ['wasm_engine_t'] => 'wasm_store_t' => sub {
  my($xsub, $class, $engine) = @_;
  $engine ||= Wasm::Wasmtime::Engine->new;
  bless {
    ptr    => $xsub->($engine->{ptr}),
    engine => $engine,
  }, $class;
});

$ffi->attach( [ 'delete' => 'DESTROY' ] => ['wasm_store_t'] => sub {
  my($xsub, $self) = @_;
  $xsub->($self->{ptr}) if $self->{ptr};
});

1;
