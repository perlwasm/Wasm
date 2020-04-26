package Wasm::Wasmtime::ExportType;

use strict;
use warnings;
use Wasm::Wasmtime::FFI;
use Wasm::Wasmtime::ExternType;

# ABSTRACT: Wasmtime export type class
# VERSION

=head1 SYNOPSIS

# EXAMPLE: examples/synopsis/exporttype.pl

=head1 DESCRIPTION

This class represents an export from a module.  It is essentially a name
and an L<Wasm::Wasmtime::ExternType>.  The latter gives you the function
signature and other configuration details for exportable objects.

=cut

$ffi_prefix = 'wasm_exporttype_';
$ffi->load_custom_type('::PtrObject' => 'wasm_exporttype_t' => __PACKAGE__);

=head1 CONSTRUCTOR

=head2 new

 my $exporttype = Wasm::Wasmtime::ExportType->new(
   $name,         # string
   $externtype,   # Wasm::Wasmtime::ExternType
 );

Creates a new export type object.

=cut

$ffi->attach( new => ['wasm_byte_vec_t*', 'wasm_externtype_t'] => 'wasm_exporttype_t' => sub {
  my $xsub = shift;
  my $class = shift;
  if(defined $_[1] && ref($_[1]) eq 'Wasm::Wasmtime::ExternType')
  {
    # not sure this is actually useful?
    # doesn't seem to bee a way to new an wasm_externtype_t
    my $name = Wasm::Wasmtime::ByteVec->new(shift);
    my $externtype = shift;
    my $self = $xsub->($name, $externtype->{ptr});
    $name->delete;
    return $self;
  }
  else
  {
    my ($ptr,$owner) = @_;
    return bless {
      ptr   => $ptr,
      owner => $owner,
    }, $class;
  }
});

=head1 METHODS

=head2 name

 my $name = $exporttype->name;

Returns the name of the export.

=cut

$ffi->attach( name => ['wasm_exporttype_t'] => 'wasm_byte_vec_t*' => sub {
  my($xsub, $self) = @_;
  my $name = $xsub->($self);
  $name->get;
});

=head2 type

 my $externtype = $exporttype->type;

Returns the L<Wasm::Wasmtime::ExternType> for the export.

=cut

$ffi->attach( type => ['wasm_exporttype_t'] => 'wasm_externtype_t' => sub {
  my($xsub, $self) = @_;
  Wasm::Wasmtime::ExternType->new(
    $xsub->($self),
    $self->{owner} || $self,
  );
});

_generate_destroy_2();
_generate_vec_class();

1;

=head1 SEE ALSO

=over 4

=item L<Wasm>

=item L<Wasm::Wasmtime>

=back

