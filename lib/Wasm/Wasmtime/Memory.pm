package Wasm::Wasmtime::Memory;

use strict;
use warnings;
use 5.008004;
use base qw( Wasm::Wasmtime::Extern );
use Ref::Util qw( is_blessed_ref is_plain_arrayref );
use Wasm::Wasmtime::FFI;
use Wasm::Wasmtime::Store;
use Wasm::Wasmtime::MemoryType;
use Carp ();
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

$ffi_prefix = 'wasmtime_memory_';

=head1 CONSTRUCTOR

=head2 new

 my $memory = Wasm::Wasmtime::Memory->new(
   $store,      # Wasm::Wasmtime::Store
   $memorytype, # Wasm::Wasmtime::MemoryType
 );

Creates a new memory object.

=cut

$ffi->attach( [ wasmtime_memory_new => 'new' ] => ['opaque', 'wasm_memorytype_t', 'wasmtime_memory_t'] => 'wasmtime_error_t' => sub {
  my $xsub = shift;
  my $class = shift;
  my($store, $memorytype) = @_;
  Carp::croak("Wasm::Wasmtime::Memory->new requires a Wasm::Wasmtime::Store")
    unless is_blessed_ref($store) && $store->isa('Wasm::Wasmtime::Store');
  $memorytype = Wasm::Wasmtime::MemoryType->new($memorytype)
    if is_plain_arrayref $memorytype;
  my $data = Wasm::Wasmtime::MemoryData->new;
  if(my $error = $xsub->($store->context, $memorytype, $data))
  {
    Carp::croak($error->message);
  }
  bless { data => $data, store => $store }, $class;
});

=head1 METHODS

=head2 type

 my $memorytype = $memory->type;

Returns the L<Wasm::Wasmtime::MemoryType> object for this memory object.

=cut

$ffi->attach( [ wasmtime_memory_type => 'type' ] => ['opaque', 'wasmtime_memory_t'] => 'wasm_memorytype_t' => sub {
  my($xsub, $self) = @_;
  $xsub->($self->context, $self->{data});
});

=head2 data

 my $pointer = $memory->data;

Returns a pointer (as an integer) to the start of the memory.

=cut

$ffi->attach( [ wasmtime_memory_data => 'data' ] => ['opaque', 'wasmtime_memory_t'] => 'opaque' => sub {
  my($xsub, $self) = @_;
  $xsub->($self->context, $self->{data});
});

=head2 data_size

 my $size = $memory->data_size;

Returns the current size of the memory in bytes.

=cut

$ffi->attach( [ wasmtime_memory_data_size => 'data_size' ] => ['opaque', 'wasmtime_memory_t'] => 'size_t' => sub {
  my($xsub, $self) = @_;
  $xsub->($self->context, $self->{data});
});

=head2 size

 my $size = $memory->size;

Returns the current size of the memory in pages.

=cut

$ffi->attach( [ wasmtime_memory_size => 'size' ] => ['opaque', 'wasmtime_memory_t'] => 'uint64' => sub {
  my($xsub, $self) = @_;
  $xsub->($self->context, $self->{data});
});

=head2 grow

 my $bool = $memory->grow($delta);

Tries to increase the page size by the given C<$delta>.  Returns true on success, false otherwise.

=cut

$ffi->attach( [ wasmtime_memory_grow => 'grow' ] => ['opaque', 'wasmtime_memory_t', 'uint64', 'uint64*'] => 'wasmtime_error_t' => sub {
  my($xsub, $self, $delta) = @_;
  my $prev = 0;
  my $error = $xsub->($self->context, $self->{data}, $delta, \$prev);
  if($error)
  {
    # match the old boolean-ish behaviour
    return !!0;
  }
  return !!1;
});

=head2 page_size

 my $bytes = $memory->page_size;

Returns the page size of this memory in bytes.  This is C<65536> (64KiB)
unless the custom-page-sizes proposal is in use.

=cut

$ffi->attach( [ wasmtime_memory_page_size => 'page_size' ] => ['opaque', 'wasmtime_memory_t'] => 'uint64' => sub {
  my($xsub, $self) = @_;
  $xsub->($self->context, $self->{data});
});

=head2 page_size_log2

 my $log2 = $memory->page_size_log2;

Returns the base-2 logarithm of this memory's page size in bytes (C<16> for
the default 64KiB page size).

=cut

$ffi->attach( [ wasmtime_memory_page_size_log2 => 'page_size_log2' ] => ['opaque', 'wasmtime_memory_t'] => 'uint8' => sub {
  my($xsub, $self) = @_;
  $xsub->($self->context, $self->{data});
});

1;

=head1 SEE ALSO

=over 4

=item L<Wasm>

=item L<Wasm::Wasmtime>

=back

=cut
