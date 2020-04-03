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

$ffi->type('char'   => 'byte_t');
$ffi->type('float'  => 'float32_t');
$ffi->type('double' => 'float64_t');

{ package Wasm::Wasmtime::Config;
  $ffi->type('object(Wasm::Wasmtime::Config)' => 'wasm_config_t');
  $ffi->mangler(sub { "wasm_config_$_[0]" });

  $ffi->attach( new => [] => 'wasm_config_t' );
  $ffi->attach( ['delete' => 'DESTROY'] => ['wasm_config_t'] );
}

{ package Wasm::Wasmtime::Engine;
  $ffi->type('object(Wasm::Wasmtime::Engine)' => 'wasm_engine_t');
  $ffi->mangler(sub { "wasm_engine_$_[0]" });

  $ffi->attach( ['new' => '_new'] => [] => 'wasm_engine_t' );
  $ffi->attach( ['new' => '_new_with_config'] => [] => 'wasm_engine_t' );
  $ffi->attach( ['delete' => 'DESTROY'] => ['wasm_engine_t'] );

  sub new
  {
    my(undef, $config) = @_;
    $config ? _new_with_config($config) : _new();
  }
}

{ package Wasm::Wasmtime::Store;
  $ffi->type('object(Wasm::Wasmtime::Store)' => 'wasm_store_t');
  $ffi->mangler(sub { "wasm_store_$_[0]" });

  $ffi->attach( new => ['wasm_engine_t'] => 'wasm_store_t' => sub {
    my($xsub, undef, $engine) = @_;
    $xsub->($engine);
  });

  $ffi->attach( ['delete' => 'DESTROY'] => ['wasm_store_t'] );
}

1;
