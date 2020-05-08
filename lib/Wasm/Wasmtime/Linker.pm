package Wasm::Wasmtime::Linker;

use strict;
use warnings;
use Wasm::Wasmtime::FFI;
use Wasm::Wasmtime::Store;
use Wasm::Wasmtime::Extern;
use Wasm::Wasmtime::Instance;
use Wasm::Wasmtime::WasiInstance;
use Wasm::Wasmtime::Trap;
use Ref::Util qw( is_blessed_ref );
use Carp ();

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
$ffi->load_custom_type('::PtrObject' => 'wasmtime_linker_t' => __PACKAGE__);

=head1 CONSTRUCTOR

=head2 new

 my $linker = Wasm::Wasmtime::Linker->new(
   $store,        # Wasm::Wasmtime::Store
 );

Create a new WebAssembly linker object.

=cut

$ffi->attach( new => ['wasm_store_t'] => 'wasmtime_linker_t' => sub {
  my($xsub, $class, $store) = @_;
  my $self = $xsub->($store);
  $self->{store} = $store;
  $self;
});

=head1 METHODS

=head2 allow_shadowing

 $linker->allow_shadowing($bool);

Sets the allow shadowing property.

=cut

$ffi->attach( allow_shadowing => [ 'wasmtime_linker_t', 'bool' ] => sub {
  my($xsub, $self, $value) = @_;
  $xsub->($self, $value);
  $self;
});

=head2 define

 $linker->define(
   $module,
   $name,
   $extern,    # Wasm::Wasmtime::Extern
 );

Define the given extern.  You can use a func, global, table or memory object in its place
and this method will get the extern for you.

=cut

if(Wasm::Wasmtime::Error->can('new'))
{
  $ffi->attach( define => ['wasmtime_linker_t', 'wasm_byte_vec_t*', 'wasm_byte_vec_t*', 'opaque'] => 'wasmtime_error_t' => sub {
    my $xsub   = shift;
    my $self   = shift;
    my $module = Wasm::Wasmtime::ByteVec->new(shift);
    my $name   = Wasm::Wasmtime::ByteVec->new(shift);
    my $extern = shift;

    # Fix this sillyness when/if ::Extern becomes a base class for extern classes
    if(is_blessed_ref($extern) && (   $extern->isa('Wasm::Wasmtime::Extern')
                                   || $extern->isa('Wasm::Wasmtime::Func')
                                   || $extern->isa('Wasm::Wasmtime::Memory')
                                   || $extern->isa('Wasm::Wasmtime::Global')
                                   || $extern->isa('Wasm::Wasmtime::Table')))
    {
      my $error = $xsub->($self, $module, $name, $extern->{ptr});
      Carp::croak($error->message) if $error;
      return $self;
    }
    else
    {
      Carp::croak("not an extern: $extern");
    }
  });
}
else
{
  $ffi->attach( define => ['wasmtime_linker_t', 'wasm_byte_vec_t*', 'wasm_byte_vec_t*', 'opaque'] => 'bool' => sub {
    my $xsub   = shift;
    my $self   = shift;
    my $module = Wasm::Wasmtime::ByteVec->new(shift);
    my $name   = Wasm::Wasmtime::ByteVec->new(shift);
    my $extern = shift;

    # Fix this sillyness when/if ::Extern becomes a base class for extern classes
    if(is_blessed_ref($extern) && (   $extern->isa('Wasm::Wasmtime::Extern')
                                   || $extern->isa('Wasm::Wasmtime::Func')
                                   || $extern->isa('Wasm::Wasmtime::Memory')
                                   || $extern->isa('Wasm::Wasmtime::Global')
                                   || $extern->isa('Wasm::Wasmtime::Table')))
    {
      my $ret = $xsub->($self, $module, $name, $extern->{ptr});
      Carp::croak("Unknown error in define") unless $ret;
      return $self;
    }
    else
    {
      Carp::croak("not an extern: $extern");
    }

  });
}

=head2 define_wasi

 $linker->define_wasi(
   $wasi,   # Wasm::Wasmtime::WasiInstance
 );

Define WASI instance.

=cut

if(Wasm::Wasmtime::Error->can('new'))
{
  $ffi->attach( define_wasi => ['wasmtime_linker_t', 'wasi_instance_t'] => 'wasmtime_error_t' => sub {
    my($xsub, $self, $wasi) = @_;
    my $error = $xsub->($self, $wasi);
    Carp::croak($error->message) if $error;
    $self;
  });
}
else
{
  $ffi->attach( define_wasi => ['wasmtime_linker_t', 'wasi_instance_t'] => 'bool' => sub {
    my($xsub, $self, $wasi) = @_;
    my $ret = $xsub->($self, $wasi);
    Carp::croak("Unknown error in define_wasi") unless $ret;
    $self;
  });
}

=head2 define_instance

 $linker->define_instance(
   $name,       # string
   $instance,   # Wasm::Wasmtime::Instance
 );

Define WebAssembly instance.

=cut

if(Wasm::Wasmtime::Error->can('new'))
{
  $ffi->attach( define_instance => ['wasmtime_linker_t', 'wasm_byte_vec_t*', 'wasm_instance_t'] => 'wasmtime_error_t' => sub {
    my($xsub, $self, $name, $instance) = @_;
    my $vname = Wasm::Wasmtime::ByteVec->new($name);
    my $error = $xsub->($self, $vname, $instance);
    Carp::croak($error->message) if $error;
    $self;
  });
}
else
{
  $ffi->attach( define_instance => ['wasmtime_linker_t', 'wasm_byte_vec_t*', 'wasm_instance_t'] => 'bool' => sub {
    my($xsub, $self, $name, $instance) = @_;
    my $vname = Wasm::Wasmtime::ByteVec->new($name);
    my $ret = $xsub->($self, $vname, $instance);
    Carp::croak("Unknown error in define_instance") unless $ret;
    $self;
  });
}

=head2 instantiate

 my $instance = $linker->instantiate(
   $module,
 );

Instantiate the module using the linker.  Returns the new L<Wasm::Wasmtime::Instance> object.

=cut

if(Wasm::Wasmtime::Error->can('new'))
{
  $ffi->attach( instantiate => ['wasmtime_linker_t','wasm_module_t','opaque*','opaque*'] => 'wasmtime_error_t' => sub {
    my($xsub, $self, $module) = @_;
    my $trap;
    my $ptr;
    my $error = $xsub->($self, $module, \$ptr, \$trap);
    Carp::croak($error->message) if $error;
    if($trap)
    {
      $trap = Wasm::Wasmtime::Trap->new($trap);
      Carp::croak($trap->message);
    }
    elsif($ptr)
    {
      return Wasm::Wasmtime::Instance->new(
        $module, $ptr,
      );
    }
    else
    {
      Carp::croak("unknown instantiate error");
    }
  });
}
else
{
  $ffi->attach( instantiate => ['wasmtime_linker_t','wasm_module_t','opaque*' ] => 'opaque' => sub {
    my($xsub, $self, $module) = @_;
    my $trap;
    my $ptr = $xsub->($self, $module, \$trap);
    if($trap)
    {
      $trap = Wasm::Wasmtime::Trap->new($trap);
      Carp::croak($trap->message);
    }
    elsif($ptr)
    {
      return Wasm::Wasmtime::Instance->new(
        $module, $ptr,
      );
    }
    else
    {
      Carp::croak("unknown instantiate error");
    }
  });
}

=head2 store

 my $store = $linker->store;

Returns the L<Wasm::Wasmtime::Store> for the linker.

=cut

sub store { shift->{store} }

_generate_destroy();

1;

=head1 SEE ALSO

=over 4

=item L<Wasm>

=item L<Wasm::Wasmtime>

=back

=cut
