package Wasm::Wasmtime::ValType;

use strict;
use warnings;
use Wasm::Wasmtime::FFI;

# ABSTRACT: Wasmtime value type class
# VERSION

$ffi_prefix = 'wasm_valtype_';
$ffi->type('opaque' => 'wasm_valtype_t');

=head1 CONSTRUCTORS

=head2 new

=cut

sub new
{
  my($class, $ptr, $owner) = @_;
  bless {
    ptr   => $ptr,
    owner => $owner,
  }, $class;
}

my %kind = (
  0   => 'i32',
  1   => 'i64',
  2   => 'f32',
  3   => 'f64',
  128 => 'anyref',
  129 => 'funcref',
);

$ffi->attach( kind => ['wasm_valtype_t'] => 'uint8' => sub {
  my($xsub, $self) = @_;
  $kind{$xsub->($self->{ptr})};
});

$ffi->attach( [kind => 'kind_num'] => ['wasm_valtype_t'] => 'uint8' => sub {
  my($xsub, $self) = @_;
  $xsub->($self->{ptr});
});

$ffi->attach( [ delete => "DESTROY" ] => ['wasm_valtype_t'] => sub {
  my($xsub, $self) = @_;
  if(defined $self->{ptr} && !defined $self->{owner})
  {
    $xsub->($self->{ptr});
  }
});

_generate_vec_class( delete => 0 );

1;
