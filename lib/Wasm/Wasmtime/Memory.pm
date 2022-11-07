package Wasm::Wasmtime::Memory;

use strict;
use warnings;
use 5.008004;
use Ref::Util qw( is_ref is_plain_arrayref is_blessed_ref );
use Wasm::Wasmtime::Extern;
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

if(_ver ne '0.27.0')
{
  $ffi_prefix = 'wasmtime_memory_';
  FFI::C->ffi($ffi);
  FFI::C->struct(
    wasmtime_memory_t => [
      _store_id => 'uint64',
      _index    => 'size_t',
    ],
  );
  *_new = \&new;
  delete $Wasm::Wasmtime::Memory::{new};
  constant->import("is_$_" => 0) for qw( func global table );
}
else
{
  $ffi_prefix = 'wasm_memory_';
  $ffi->load_custom_type('::PtrObject' => 'wasm_memory_t' => __PACKAGE__);
  our @ISA;                              ## no critic (ClassHierarchies::ProhibitExplicitISA)
  push @ISA, 'Wasm::Wasmtime::Extern';   ## no critic (ClassHierarchies::ProhibitExplicitISA)
}

=head1 CONSTRUCTOR

=head2 new

 my $memory = Wasm::Wasmtime::Memory->new(
   $context,    # Wasm::Wasmtime::Context
   $memorytype, # Wasm::Wasmtime::MemoryType
 );

Creates a new memory object.

=cut

if(_ver ne '0.27.0')
{
  $ffi->attach( new => ['wasmtime_context_t','wasm_memorytype_t','wasmtime_memory_t'] => 'wasmtime_error_t' => sub {
    my $xsub = shift;
    my $class = shift;
    if(is_ref $_[0])
    {
      my $context;
      if(is_blessed_ref($_[0]) && $_[0]->isa('Wasm::Wasmtime::Store'))
      {
        Carp::carp("Passing Store is deprecated, please pass a \$store->context instead");
        $context = shift->context;
      }
      elsif(is_blessed_ref($_[0]) && $_[0]->isa('Wasm::Wasmtime::Context'))
      {
        $context = shift;
      }
      else
      {
        Carp::croak("Must pass in a Wasm::Wasmtime::Store or Wasm::Wasmtime::Context");
      }
      my $memorytype = shift;
      $memorytype = Wasm::Wasmtime::MemoryType->new($memorytype)
        if is_plain_arrayref $memorytype;
      my $self = __PACKAGE__->_new;
      my $error = $xsub->($context, $memorytype, $self);
      if($error)
      {
        Carp::croak("error creating memory: " . $error->message);
      }
      $self->{context} = $context;
      return $self;
    }
    else
    {
      Carp::croak('todo');
    }

  });
}
else
{
  $ffi->attach( new => ['wasm_store_t', 'wasm_memorytype_t'] => 'wasm_memory_t' => sub {
    my $xsub = shift;
    my $class = shift;
    if(is_ref $_[0])
    {
      my $store;
      if(is_blessed_ref($_[0]) && $_[0]->isa('Wasm::Wasmtime::Store'))
      {
        Carp::carp("Passing Store is deprecated, please pass a \$store->context instead");
        $store = shift;
      }
      elsif(is_blessed_ref($_[0]) && $_[0]->isa('Wasm::Wasmtime::Context'))
      {
        $store = shift->{store};
      }
      else
      {
        Carp::croak("Must pass in a Wasm::Wasmtime::Store or Wasm::Wasmtime::Context");
      }
      my $memorytype = shift;
      $memorytype = Wasm::Wasmtime::MemoryType->new($memorytype)
        if is_plain_arrayref $memorytype;
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
}

=head1 METHODS

=head2 type

 my $memorytype = $memory->type;

Returns the L<Wasm::Wasmtime::MemoryType> object for this memory object.

=cut

if(_ver ne '0.27.0')
{
  $ffi->attach( type => ['wasmtime_context_t', 'wasmtime_memory_t'] => 'wasm_memorytype_t' => sub {
    my($xsub, $self) = @_;
    $xsub->($self->{context}, $self);
  });
}
else
{
  $ffi->attach( type => ['wasm_memory_t'] => 'wasm_memorytype_t' => sub {
    my($xsub, $self) = @_;
    my $type = $xsub->($self);
    $type->{owner} = $self->{owner} || $self if $type;
    $type;
  });
}

=head2 data

 my $pointer = $memory->data;

Returns a pointer to the start of the memory.

=cut

if(_ver ne '0.27.0')
{
  $ffi->attach( data => ['wasmtime_context_t', 'wasmtime_memory_t'] => 'opaque' => sub {
    my($xsub, $self) = @_;
    $xsub->($self->{context}, $self);
  });
}
else
{
  $ffi->attach( data => ['wasm_memory_t'] => 'opaque' => sub {
    my($xsub, $self) = @_;
    $xsub->($self);
  });
}

=head2 data_size

 my $size = $memory->data_size;

Returns the current size of the memory in bytes.

=cut

if(_ver ne '0.27.0')
{
  $ffi->attach( data_size => ['wasmtime_context_t', 'wasmtime_memory_t'] => 'size_t' => sub {
    my($xsub, $self) = @_;
    $xsub->($self->{context}, $self);
  });
}
else
{
  $ffi->attach( data_size => ['wasm_memory_t'] => 'size_t' => sub {
    my($xsub, $self) = @_;
    $xsub->($self);
  });
}

=head2 size

 my $size = $memory->size;

Returns the current size of the memory in pages.

=cut

if(_ver ne '0.27.0')
{
  $ffi->attach( size => ['wasmtime_context_t', 'wasmtime_memory_t'] => 'uint32' => sub {
    my($xsub, $self) = @_;
    $xsub->($self->{context}, $self);
  });
}
else
{
  $ffi->attach( size => ['wasm_memory_t'] => 'uint32' => sub {
    my($xsub, $self) = @_;
    $xsub->($self);
  });
}

=head2 grow

 my $bool = $memory->grow($delta);

Tries to increase the page size by the given C<$delta>.  Throws an exception in the case of
an error.

=cut

if(_ver ne '0.27.0')
{
  $ffi->attach( grow => ['wasmtime_context_t','wasmtime_memory_t', 'uint32','uint32*'] => 'bool' => sub {
    my($xsub, $self, $delta) = @_;
    my $error = $xsub->($self->{context}, $self, $delta, \my $old);
    if($error)
    {
        Carp::croak("error creating memory: " . $error->message);
    }
    # TODO maybe return $old?   Now that we are throwing an
    # exception on error?
    return $old;
  });
}
else
{
  $ffi->attach( grow => ['wasm_memory_t', 'uint32'] => 'bool' => sub {
    my($xsub, $self, $delta) = @_;
    $xsub->($self, $delta) || die "error growing memory";
    return '';
  });


  __PACKAGE__->_cast(3);
  _generate_destroy();
}

1;

=head1 SEE ALSO

=over 4

=item L<Wasm>

=item L<Wasm::Wasmtime>

=back

=cut
