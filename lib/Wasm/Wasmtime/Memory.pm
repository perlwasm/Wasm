package Wasm::Wasmtime::Memory;

use strict;
use warnings;
use base qw( Wasm::Wasmtime::Extern );
use Ref::Util qw( is_ref );
use Wasm::Wasmtime::FFI;
use Wasm::Wasmtime::Store;
use Wasm::Wasmtime::MemoryType;
use constant is_memory => 1;
use constant kind => 'memory';

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
$ffi->load_custom_type('::PtrObject' => 'wasm_memory_t' => __PACKAGE__);

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
  if(is_ref $_[0])
  {
    my($store, $memorytype) = @_;
    return $xsub->($store, $memorytype);
  }
  else
  {
    my($ptr, $owner) = @_;
    return bless {
      ptr   => $ptr,
      owner => $owner,
    }, $class;
  }
});

=head1 METHODS

=head2 type

 my $memorytype = $memory->type;

Returns the L<Wasm::Wasmtime::MemoryType> object for this memory object.

=cut

$ffi->attach( type => ['wasm_memory_t'] => 'wasm_memorytype_t' => sub {
  my($xsub, $self) = @_;
  my $type = $xsub->($self);
  $type->{owner} = $self->{owner} || $self if $type;
  $type;
});

=head2 data

 my $pointer = $memory->data;

Returns a pointer to the start of the memory.

=cut

$ffi->attach( data => ['wasm_memory_t'] => 'opaque' => sub {
  my($xsub, $self) = @_;
  $xsub->($self);
});

=head2 data_size

 my $size = $memory->data_size;

Returns the current size of the memory in bytes.

=cut

$ffi->attach( data_size => ['wasm_memory_t'] => 'size_t' => sub {
  my($xsub, $self) = @_;
  $xsub->($self);
});

=head2 size

 my $size = $memory->size;

Returns the current size of the memory in pages.

=cut

$ffi->attach( size => ['wasm_memory_t'] => 'uint32' => sub {
  my($xsub, $self) = @_;
  $xsub->($self);
});

=head2 grow

 my $bool = $memory->grow($delta);

Tries to increase the page size by the given C<$delta>.  Returns true on success, false otherwise.

=cut

$ffi->attach( grow => ['wasm_memory_t', 'uint32'] => 'bool' => sub {
  my($xsub, $self, $delta) = @_;
  $xsub->($self, $delta);
});

__PACKAGE__->_cast(3);
_generate_destroy();

1;

=head1 SEE ALSO

=over 4

=item L<Wasm>

=item L<Wasm::Wasmtime>

=back

