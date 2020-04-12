package Wasm::Wasmtime::Linker;

use strict;
use warnings;
use Wasm::Wasmtime::FFI;
use Wasm::Wasmtime::Store;
use Wasm::Wasmtime::Extern;
use Ref::Util qw( is_blessed_ref );

# ABSTRACT: Wasmtime linker class
# VERSION

=head1 SYNOPSIS

# EXAMPLE: examples/synopsis/linker.pl

=head1 DESCRIPTION

B<WARNING>: WebAssembly and Wasmtime are a moving target and the interface for these modules
is under active development.  Use with caution.

This class represents a WebAssembly linker.

=cut

$ffi_prefix = 'wasmtime_linker_';
$ffi->type('opaque' => 'wasmtime_linker_t');

=head1 CONSTRUCTOR

=head2 new

 my $linker = Wasm::Wasmtime::Linker->new(
   $store,        # Wasm::Wasmtime::Store
 );

Create a new WebAssembly linker object.

=cut

$ffi->attach( new => ['wasm_store_t'] => 'wasmtime_linker_t' => sub {
  my($xsub, $class, $store) = @_;
  my $ptr = $xsub->($store->{ptr});
  bless { ptr => $ptr, store => $store }, $class;
});

=head1 METHODS

=head2 allow_shadowing

 $linker->allow_shadowing($bool);

Sets the allow shadowing property.

=cut

$ffi->attach( allow_shadowing => [ 'wasmtime_linker_t', 'bool' ] => sub {
  my($xsub, $self, $value) = @_;
  $xsub->($self->{ptr}, $value);
  $self;
});

=head2 define

 $linker->define(
   $module,
   $name,
   $extern,    # Wasm::Wasmtime::Extern
 );

Define the given extern.  You can use a func, global, table ot memory object in its place
and this method will get the extern for you.

=cut

$ffi->attach( define => ['wasmtime_linker_t', 'wasm_byte_vec_t*', 'wasm_byte_vec_t*', 'wasm_extern_t'] => 'wasmtime_error_t' => sub {
  my $xsub   = shift;
  my $self   = shift;
  my $module = Wasm::Wasmtime::ByteVec->new(shift);
  my $name   = Wasm::Wasmtime::ByteVec->new(shift);
  my $extern = shift;

  if(ref($extern) eq 'Wasm::Wasmtime::Extern')
  {
    # nothing, okay.
  }
  elsif(is_blessed_ref($extern) && $extern->can('as_extern'))
  {
    $extern = $extern->as_extern;
  }
  else
  {
    Carp::croak("not an extern: $extern");
  }

  $xsub->($self->{ptr}, $module, $name, $extern->{ptr});
  $self;
});

$ffi->attach( [ 'delete' => 'DESTROY' ] => ['wasmtime_linker_t'] => sub {
  my($xsub, $self) = @_;
  $xsub->($self->{ptr}) if $self->{ptr};
});

1;
