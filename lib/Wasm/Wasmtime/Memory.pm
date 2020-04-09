package Wasm::Wasmtime::Memory;

use strict;
use warnings;
use Wasm::Wasmtime::FFI;
use Wasm::Wasmtime::MemoryType;

# ABSTRACT: Wasmtime memory class
# VERSION

$ffi_prefix = 'wasm_memory_';
$ffi->type('opaque' => 'wasm_memory_t');

=head1 CONSTRUCTORS

=head2 new

=cut

sub new
{
  my($class, $ptr, $owner) = @_;
  bless {
    ptr   => $ptr,
    owner => $owner,
  }, $class;
}

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
