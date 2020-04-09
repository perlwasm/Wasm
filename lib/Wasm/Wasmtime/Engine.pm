package Wasm::Wasmtime::Engine;

use strict;
use warnings;
use Wasm::Wasmtime::FFI;
use Wasm::Wasmtime::Config;

# ABSTRACT: Wasmtime engine class
# VERSION

$ffi_prefix = 'wasm_engine_';
$ffi->type('opaque' => 'wasm_engine_t');

$ffi->attach( [ 'new_with_config' => 'new' ] => ['wasm_config_t'] => 'wasm_engine_t' => sub {
  my($xsub, $class, $config) = @_;
  $config ||= Wasm::Wasmtime::Config->new;
  bless {
    ptr => $xsub->(delete $config->{ptr}),
  }, $class;
});

$ffi->attach( [ 'delete' => 'DESTROY' ] => ['wasm_engine_t'] => sub {
  my($xsub, $self) = @_;
  $xsub->($self->{ptr}) if $self->{ptr};
});

1;
