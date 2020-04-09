package Wasm::Wasmtime::MemoryType;

use strict;
use warnings;
use Wasm::Wasmtime::FFI;

# ABSTRACT: Wasmtime memory type class
# VERSION

$ffi_prefix = 'wasm_memorytype_';
$ffi->type('opaque' => 'wasm_memorytype_t');

$ffi->attach( new => ['uint32[2]'] => 'wasm_memorytype_t' => sub {
  my $xsub = shift;
  my $class = shift;
  my $ptr;
  my $owner;
  if(ref $_[0])
  {
    $ptr = $xsub->(shift);
  }
  else
  {
    ($ptr, $owner) = @_;
  }
  bless {
    ptr => $ptr,
    owner => $owner,
  }, $class;
});

$ffi->attach( limits => ['wasm_memorytype_t'] => 'uint32[2]' => sub {
  my($xsub, $self) = @_;
  my $limits = $xsub->($self->{ptr});
  $limits;
});

$ffi->attach( [ delete => "DESTROY" ] => ['wasm_memorytype_t'] => sub {
  my($xsub, $self) = @_;
  if(defined $self->{ptr} && !defined $self->{owner})
  {
    $xsub->($self->{ptr});
  }
});

1;
