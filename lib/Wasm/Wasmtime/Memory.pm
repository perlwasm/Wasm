package Wasm::Wasmtime::Memory;

use strict;
use warnings;
use Ref::Util qw( is_ref );
use Wasm::Wasmtime::FFI;
use Wasm::Wasmtime::Store;
use Wasm::Wasmtime::MemoryType;

# ABSTRACT: Wasmtime memory class
# VERSION

=head1 SYNOPSIS

# EXAMPLE: examples/synopsis/memory.pl

=head1 DESCRIPTION

B<WARNING>: WebAssembly and Wasmtime are a moving target and the interface for these modules
is under active development.  Use with caution.

This class represents a WebAssembly memory object.

=cut

$ffi_prefix = 'wasm_memory_';
$ffi->type('opaque' => 'wasm_memory_t');

=head1 CONSTRUCTOR

=head2 new

 my $memory = Wasm::Wasmtime::Memory->new(
   $store,      # Wasm::Wasmtime::Store
   $memorytype, # Wasm::Wasmtime::MemoryType
 );

Creates a new memory object.

=cut

$ffi->attach( new => ['wasm_store_t', 'wasm_memorytype_t'] => 'wasm_memory_t' => sub {
  my $xsub = shift;
  my $class = shift;
  my $ptr;
  my $owner;
  if(is_ref $_[0])
  {
    my($store, $memorytype) = @_;
    $ptr = $xsub->($store->{ptr}, $memorytype->{ptr});
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

=head1 METHODS

=head2 type

 my $memorytype = $memory->type;

Returns the L<Wasm::Wasmtime::MemoryType> object for this memory object.

=cut

$ffi->attach( type => ['wasm_memory_t'] => 'wasm_memorytype_t' => sub {
  my($xsub, $self) = @_;
  Wasm::Wasmtime::MemoryType->new($xsub->($self->{ptr}), $self->{owner} || $self);
});

=head2 data

 my $pointer = $memory->data;

Returns a pointer to the start of the memory.

=cut

$ffi->attach( data => ['wasm_memory_t'] => 'opaque' => sub {
  my($xsub, $self) = @_;
  $xsub->($self->{ptr});
});

=head2 data_size

 my $size = $memory->data_size;

Returns the current size of the memory in bytes.

=cut

$ffi->attach( data_size => ['wasm_memory_t'] => 'size_t' => sub {
  my($xsub, $self) = @_;
  $xsub->($self->{ptr});
});

=head2 size

 my $size = $memory->size;

Returns the current size of the memory in pages.

=cut

$ffi->attach( size => ['wasm_memory_t'] => 'uint32' => sub {
  my($xsub, $self) = @_;
  $xsub->($self->{ptr});
});

=head2 grow

 my $bool = $memory->grow($delta);

Tries to increase the page size by the given C<$delta>.  Returns true on success, false otherwise.

=cut

$ffi->attach( grow => ['wasm_memory_t', 'uint32'] => 'bool' => sub {
  my($xsub, $self, $delta) = @_;
  $xsub->($self->{ptr}, $delta);
});

=head2 as_extern

 my $extern = $memory->as_extern;

Returns the L<Wasm::Wasmtime::Extern> for this memory object.

=cut

# actually returns a wasm_extern_t, but recursion
$ffi->attach( as_extern => ['wasm_memory_t'] => 'opaque' => sub {
  my($xsub, $self) = @_;
  require Wasm::Wasmtime::Extern;
  my $ptr = $xsub->($self->{ptr});
  Wasm::Wasmtime::Extern->new($ptr, $self->{owner} || $self);
});

$ffi->attach( [ delete => "DESTROY" ] => ['wasm_memory_t'] => sub {
  my($xsub, $self) = @_;
  if(defined $self->{ptr} && !defined $self->{owner})
  {
    $xsub->($self->{ptr});
  }
});

1;

=head1 SEE ALSO

=over 4

=item L<Wasm>

=item L<Wasm::Wasmtime>

=back

