package Wasm::Wasmtime::ValType;

use strict;
use warnings;
use Wasm::Wasmtime::FFI;

# ABSTRACT: Wasmtime value type class
# VERSION

=head1 SYNOPSIS

# EXAMPLE: examples/synopsis/valtype.pl

=head1 DESCRIPTION

B<WARNING>: WebAssembly and Wasmtime are a moving target and the interface for these modules
is under active development.  Use with caution.

This class represents a Wasm type.

=cut

$ffi_prefix = 'wasm_valtype_';
$ffi->load_custom_type('::PtrObject' => 'wasm_valtype_t' => __PACKAGE__);

my %kind = (
  0   => 'i32',
  1   => 'i64',
  2   => 'f32',
  3   => 'f64',
  128 => 'anyref',
  129 => 'funcref',
);

my %rkind;
foreach my $key (keys %kind)
{
  my $value = $kind{$key};
  $rkind{$value} = $key;
}

=head1 CONSTRUCTOR

=head2 new

 my $valtype = Wasm::Wasmtime::ValType->new($type);

Creates a new value type instance.  Acceptable values for C<$type> are:

=over 4

=item C<i32>

Signed 32 bit integer.

=item C<i64>

Signed 64 bit integer.

=item C<f32>

Floating point.

=item C<f64>

Double precision floating point.

=item C<anyref>

A pointer.

=item C<funcref>

A function pointer.

=back

=cut

$ffi->attach( new => ['uint8'] => 'wasm_valtype_t' => sub {
  my $xsub = shift;
  my $class = shift;
  if($_[0] =~ /^[0-9]+$/)
  {
    my($ptr, $owner) = @_;
    return bless {
      ptr   => $ptr,
      owner => $owner,
    }, $class;
  }
  else
  {
    my($kind) = @_;
    my $kind_num = $rkind{$kind};
    Carp::croak("no such value type: $kind") unless defined $kind_num;
    return $xsub->($kind_num);
  }
});

=head1 METHODS

=head2 kind

 my $kind = $valtype->kind;

Returns the value type as a string (ie C<i32>).

=cut

sub kind { $kind{shift->kind_num} }

=head2 kind_num

 my $kind = $valtype->kind_num;

Returns the number used internally to represent the type.

=cut

$ffi->attach( [kind => 'kind_num'] => ['wasm_valtype_t'] => 'uint8' );

_generate_destroy_2();
_generate_vec_class( delete => 0 );

$ffi->attach( [ wasm_valtype_vec_new => 'Wasm::Wasmtime::ValTypeVec::set' ] => ['wasm_valtype_vec_t*','size_t','opaque[]'] => sub {
  my($xsub, $self, $valtypes) = @_;
  $xsub->($self, scalar(@$valtypes), $valtypes);
  $self;
});

1;

=head1 SEE ALSO

=over 4

=item L<Wasm>

=item L<Wasm::Wasmtime>

=back

