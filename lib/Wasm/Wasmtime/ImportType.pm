package Wasm::Wasmtime::ImportType;

use strict;
use warnings;
use Carp ();
use Ref::Util qw( is_blessed_ref );
use Wasm::Wasmtime::FFI;
use Wasm::Wasmtime::ExternType;

# ABSTRACT: Wasmtime import type class
# VERSION

=head1 SYNOPSIS

# EXAMPLE: examples/synopsis/importtype.pl

=head1 DESCRIPTION

This class represents an import from a module.  It is essentially a name
and an L<Wasm::Wasmtime::ExternType>.  The latter gives you the function
signature and other configuration details for import objects.

=cut

$ffi_prefix = 'wasm_importtype_';
$ffi->load_custom_type('::PtrObject' => 'wasm_importtype_t' => __PACKAGE__);

=head1 CONSTRUCTOR

=head2 new

 my $importtype = Wasm::Wasmtime::ImportType->new(
   $module,       # Wasm::Wasmtime::Module
   $name,         # string
   $externtype,   # Wasm::Wasmtime::FuncType, ::MemoryType, ::GlobalType or ::TableType
 );

Creates a new import type object.

=cut

$ffi->attach( new => ['wasm_byte_vec_t*', 'wasm_byte_vec_t*', 'opaque'] => 'wasm_importtype_t' => sub {
  my $xsub = shift;
  my $class = shift;
  if(defined $_[2] && is_blessed_ref $_[2])
  {
    my $externtype = $_[2];
    # not sure this is actually useful?
    if(is_blessed_ref($externtype) && $externtype->isa('Wasm::Wasmtime::ExternType'))
    {
      my $module = Wasm::Wasmtime::ByteVec->new(shift);
      my $name = Wasm::Wasmtime::ByteVec->new(shift);
      my $self = $xsub->($module, $name, $externtype->{ptr});
      $module->delete;
      $name->delete;
      return $self;
    }
    else
    {
      Carp::croak("Not an externtype");
    }
  }
  else
  {
    my($ptr,$owner) = @_;
    return bless {
      ptr   => $ptr,
      owner => $owner,
    }, $class;
  }
});

=head1 METHODS

=head2 name

 my $name = $importtype->name;

Returns the name of the import.

=cut

$ffi->attach( name => ['wasm_importtype_t'] => 'wasm_byte_vec_t*' => sub {
  my($xsub, $self) = @_;
  my $name = $xsub->($self);
  $name->get;
});

=head2 type

 my $externtype = $importtype->type;

Returns the L<Wasm::Wasmtime::ExternType> for the import.

=cut

$ffi->attach( type => ['wasm_importtype_t'] => 'wasm_externtype_t' => sub {
  my($xsub, $self) = @_;
  my $type = $xsub->($self);
  $type->{owner} = $self->{owner} || $self;
  $type;
});

=head2 module

 my $name = $importtype->module;

Returns the name of the module for the import.

=cut

$ffi->attach( module => ['wasm_importtype_t'] => 'wasm_byte_vec_t*' => sub {
  my($xsub, $self) = @_;
  my $name = $xsub->($self);
  $name->get;
});

_generate_destroy();
_generate_vec_class();

1;

=head1 SEE ALSO

=over 4

=item L<Wasm>

=item L<Wasm::Wasmtime>

=back

