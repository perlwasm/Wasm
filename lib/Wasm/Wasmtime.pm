package Wasm::Wasmtime;

use strict;
use warnings;
use 5.008001;
use Alien::wasmtime;
use FFI::Platypus 1.00;

# ABSTRACT: Write Perl interface to wasmtime
# VERSION

my $ffi = FFI::Platypus->new(
  api => 1,
  lib => [Alien::wasmtime->dynamic_libs],
);

{ package Wasm::Wasmtime::Engine;

  $ffi->type('object(Wasm::Wasmtime::Engine)' => 'wasm_engine_t');
  $ffi->mangler(sub { "wasm_engine_$_[0]" });

  $ffi->attach( new => [] => 'wasm_engine_t' );
  $ffi->attach( ['delete' => 'DESTROY'] => ['wasm_engine_t'] );
}

1;
