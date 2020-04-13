package Wasm::Wasmtime::TableType;

use strict;
use warnings;
use Wasm::Wasmtime::FFI;
use Wasm::Wasmtime::ValType;
use Ref::Util qw( is_ref );

# ABSTRACT: Wasmtime table type class
# VERSION

=head1 SYNOPSIS

# EXAMPLE: examples/synopsis/tabletype.pl

=head1 DESCRIPTION

B<WARNING>: WebAssembly and Wasmtime are a moving target and the interface for these modules
is under active development.  Use with caution.

This class represents a module table type.

=cut

$ffi_prefix = 'wasm_tabletype_';
$ffi->type('opaque' => 'wasm_tabletype_t');

=head1 CONSTRUCTOR

=head2 new

 my $tabletype = Wasm::Wasmtime::TableType->new(
   $valtype,     # Wasm::Wasmtime::ValType
   [$min,$max],  # integer limits
 );

Creates a new table type object.

As a shortcut, the type names (ie C<i32>, etc) maybe used instead of a L<Wasm::Wasmtime::ValType>
for C<$valtype>.

=cut

$ffi->attach( new => ['wasm_valtype_t','uint8[2]'] => 'wasm_tabletype_t' => sub {
  my $xsub = shift;
  my $class = shift;
  my $ptr;
  my $owner;
  if(defined $_[0] && !is_ref($_[0]) && $_[0] =~ /^[0-9]+$/)
  {
    ($ptr, $owner) = @_;
  }
  else
  {
    my($valtype, $limit) = @_;
    if(ref($valtype) eq 'Wasm::Wasmtime::ValType')
    {
      $valtype = Wasm::Wasmtime::ValType->new($valtype->kind);
    }
    else
    {
      $valtype = Wasm::Wasmtime::ValType->new($valtype);
    }
    $ptr = $xsub->(delete $valtype->{ptr}, $limit);
  }
  bless {
    ptr => $ptr,
    owner => $owner,
  }, $class;
});

=head2 element

 my $valtype = $tabletype->element;

Returns the L<Wasm::Wasmtime::ValType> for this table type.

=cut

$ffi->attach( element => ['wasm_tabletype_t'] => 'wasm_valtype_t' => sub {
  my($xsub, $self) = @_;
  my $ptr = $xsub->($self->{ptr});
  Wasm::Wasmtime::ValType->new($ptr, $self);
});

=head2 as_externtype

 my $externtype = $tabletype->as_externtype

Returns the L<Wasm::Wasmtime::ExternType> for this table type.

=cut

# actually returns a wasm_externtype_t, but recursion
$ffi->attach( as_externtype => ['wasm_tabletype_t'] => 'opaque' => sub {
  my($xsub, $self) = @_;
  require Wasm::Wasmtime::ExternType;
  my $ptr = $xsub->($self->{ptr});
  Wasm::Wasmtime::ExternType->new($ptr, $self->{owner} || $self);
});

$ffi->attach( [ delete => "DESTROY" ] => ['wasm_tabletype_t'] => sub {
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

