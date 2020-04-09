package Wasm::Wasmtime::Trap;

use strict;
use warnings;
use Wasm::Wasmtime::FFI;
use Wasm::Wasmtime::Store;

# ABSTRACT: Wasmtime trap class
# VERSION

$ffi_prefix = 'wasm_trap_';
$ffi->type('opaque' => 'wasm_trap_t');

$ffi->attach( new => [ 'wasm_store_t', 'wasm_byte_vec_t*' ] => 'wasm_trap_t' => sub {
  my $xsub = shift;
  my $class = shift;
  if(@_ == 1)
  {
    my $pointer = shift;
    return bless {
      ptr => $pointer,
    }, $class;
  }
  else
  {
    my $store = shift;
    my $message = Wasm::Wasmtime::ByteVec->new($_[0]);
    return bless {
      ptr => $xsub->($store->{ptr}, $message),
    }, $class;
  }
});

$ffi->attach( message => ['wasm_trap_t', 'wasm_byte_vec_t*'] => sub {
  my($xsub, $self) = @_;
  my $message = Wasm::Wasmtime::ByteVec->new;
  $xsub->($self->{ptr}, $message);
  my $ret = $message->get;
  $ret =~ s/\0$//;
  $message->delete;
  $ret;
});

$ffi->attach( [ 'delete' => 'DESTROY' ] => ['wasm_trap_t'] => sub {
  my($xsub, $self) = @_;
  $xsub->($self->{ptr}) if $self->{ptr};
});

1;
