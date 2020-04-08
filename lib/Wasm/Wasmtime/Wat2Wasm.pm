package Wasm::Wasmtime::Wat2Wasm;

use strict;
use warnings;
use Wasm::Wasmtime::FFI;
use base qw( Exporter );

# ABSTRACT: Convert WebAssembly Text to Wasm
# VERSION

our @EXPORT = qw( wat2wasm );

$ffi->mangler(sub { "wasmtime_$_[0]" });

$ffi->attach( wat2wasm => ['wasm_byte_vec_t*','wasm_byte_vec_t*','wasm_byte_vec_t*'] => 'bool' => sub {
  my $xsub = shift;
  my $wat = Wasm::Wasmtime::ByteVec->new($_[0]);
  my $ret = Wasm::Wasmtime::ByteVec->new;
  my $error_message = Wasm::Wasmtime::ByteVec->new;
  if($xsub->($wat, $ret, $error_message))
  {
    my $wasm = $ret->get;
    $ret->delete;
    return $wasm;
  }
  else
  {
    my $diag = $error_message->get;
    $error_message->delete;
    Carp::croak($diag . "\nwat2wasm error");
  }
});

1;
