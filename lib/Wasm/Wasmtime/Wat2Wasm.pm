package Wasm::Wasmtime::Wat2Wasm;

use strict;
use warnings;
use Wasm::Wasmtime::FFI;
use base qw( Exporter );

# ABSTRACT: Convert WebAssembly Text to Wasm
# VERSION

=head1 SYNOPSIS

# EXAMPLE: examples/synopsis/wat2wasm.pl

=head1 DESCRIPTION

This module provides C<wat2wasm>, a function for converting WebAssembly Text to WebAssembly binary format (Wasm).
It is exported by default.

=cut

our @EXPORT = qw( wat2wasm );

$ffi_prefix = 'wasmtime_';

=head1 FUNCTIONS

=head2 wat2wasm

 my $wasm = wat2wasm($wat);

Takes WebAssembly Text C<$wat> and converts it into the WebAssembly binary C<$wasm>.

=cut

if(Wasm::Wasmtime::Error->can('new'))
{
  $ffi->attach( wat2wasm => ['wasm_byte_vec_t*','wasm_byte_vec_t*'] => 'wasmtime_error_t' => sub {
    my $xsub = shift;
    my $wat = Wasm::Wasmtime::ByteVec->new($_[0]);
    my $ret = Wasm::Wasmtime::ByteVec->new;
    my $error = $xsub->($wat, $ret);
    if($error)
    {
      Carp::croak($error->message . "\nwat2wasm error");
    }
    else
    {
      my $wasm = $ret->get;
      $ret->delete;
      return $wasm;
    }
  });
}
else
{
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
}

1;
