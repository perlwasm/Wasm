package Wasm::Wasmtime::FFI;

use strict;
use warnings;
use FFI::Platypus 1.00;
use FFI::Platypus::Buffer ();
use Alien::wasmtime;
use base qw( Exporter );

# ABSTRACT: Private class for Wasm::Wasmtime
# VERSION

our @EXPORT = qw( $ffi );

our $ffi = FFI::Platypus->new( api => 1 );
$ffi->lib(Alien::wasmtime->dynamic_libs);

{ package Wasm::Wasmtime::Vec;
  use FFI::Platypus::Record;
  record_layout_1(
    $ffi,
    size_t => 'size',
    opaque => 'data',
  );
}

{ package Wasm::Wasmtime::ByteVec;
  use base qw( Wasm::Wasmtime::Vec );

  $ffi->type('record(Wasm::Wasmtime::ByteVec)' => 'wasm_byte_vec_t');
  $ffi->mangler(sub { "wasm_byte_vec_$_[0]" });

  sub new
  {
    my $class = shift;
    if(@_ == 1)
    {
      my($data, $size) = FFI::Platypus::Buffer::scalar_to_buffer($_[0]);
      return $class->SUPER::new(
        size => $size,
        data => $data,
      );
    }
    else
    {
      return $class->SUPER::new(@_);
    }
  }

  sub get
  {
    my($self) = @_;
    FFI::Platypus::Buffer::buffer_to_scalar($self->data, $self->size);
  }

  $ffi->attach( delete => ['wasm_byte_vec_t*'] => 'void' );
}

1;
