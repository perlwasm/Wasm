package Wasm::Wasmtime::ImportType;

use strict;
use warnings;
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
   $externtype,   # Wasm::Wasmtime::ExternType
 );

Creates a new import type object.

=cut

$ffi->attach( new => ['wasm_byte_vec_t*', 'wasm_externtype_t'] => 'wasm_importtype_t' => sub {
  my $xsub = shift;
  my $class = shift;
  if(defined $_[2] && ref($_[2]) eq 'Wasm::Wasmtime::ExternType')
  {
    my $module = Wasm::Wasmtime::ByteVec->new(shift);
    my $name = Wasm::Wasmtime::ByteVec->new(shift);
    my $externtype = shift;
    my $self = $xsub->($module, $name, $externtype);
    $module->delete;
    $name->delete;
    $self;
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

