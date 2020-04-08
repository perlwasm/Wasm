package Wasm::Wasmtime::FFI;

use strict;
use warnings;
use FFI::Platypus 1.00;
use Alien::wasmtime;
use base qw( Exporter );

# ABSTRACT: Private class for Wasm::Wasmtime
# VERSION

our @EXPORT = qw( $ffi );

our $ffi = FFI::Platypus->new( api => 1 );
$ffi->lib(Alien::wasmtime->dynamic_libs);

1;
