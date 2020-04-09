package Wasm::Wasmtime::Memory;

use strict;
use warnings;
use Wasm::Wasmtime::FFI;
use Wasm::Wasmtime::Store;
use Wasm::Wasmtime::MemoryType;

# ABSTRACT: Wasmtime memory class
# VERSION

$ffi_prefix = 'wasm_memory_';
$ffi->type('opaque' => 'wasm_memory_t');

$ffi->attach( new => ['wasm_store_t', 'wasm_memorytype_t'] => 'wasm_memory_t' => sub {
  my $xsub = shift;
  my $class = shift;
  my $ptr;
  my $owner;
  if(ref $_[0])
  {
    my($store, $memorytype) = @_;
    $ptr = $xsub->($store->{ptr}, $memorytype->{ptr});
    $owner = [$store, $memorytype];
  }
  else
  {
    ($ptr, $owner) = @_;
  }
  bless {
    ptr   => $ptr,
    owner => $owner,
  }, $class;
});

$ffi->attach( type => ['wasm_memory_t'] => 'wasm_memorytype_t' => sub {
  my($xsub, $self) = @_;
  Wasm::Wasmtime::MemoryType->new($xsub->($self->{ptr}), $self->{owner} || $self);
});

$ffi->attach( data => ['wasm_memory_t'] => 'opaque' => sub {
  my($xsub, $self) = @_;
  $xsub->($self->{ptr});
});

$ffi->attach( data_size => ['wasm_memory_t'] => 'size_t' => sub {
  my($xsub, $self) = @_;
  $xsub->($self->{ptr});
});

$ffi->attach( size => ['wasm_memory_t'] => 'uint32' => sub {
  my($xsub, $self) = @_;
  $xsub->($self->{ptr});
});

$ffi->attach( grow => ['wasm_memory_t', 'uint32'] => 'bool' => sub {
  my($xsub, $self, $delta) = @_;
  $xsub->($self->{ptr}, $delta);
});

$ffi->attach( [ delete => "DESTROY" ] => ['wasm_memory_t'] => sub {
  my($xsub, $self) = @_;
  if(defined $self->{ptr} && !defined $self->{owner})
  {
    $xsub->($self->{ptr});
  }
});

1;
