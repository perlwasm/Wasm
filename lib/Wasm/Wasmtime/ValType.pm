package Wasm::Wasmtime::ValType;

use strict;
use warnings;
use Wasm::Wasmtime::FFI;

# ABSTRACT: Wasmtime value type class
# VERSION

$ffi_prefix = 'wasm_valtype_';
$ffi->type('opaque' => 'wasm_valtype_t');

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

$ffi->attach( new => ['uint8'] => 'wasm_valtype_t' => sub {
  my $xsub = shift;
  my $class = shift;
  my($ptr, $owner);
  if($_[0] =~ /^[0-9]+$/)
  {
    ($ptr, $owner) = @_;
  }
  else
  {
    my($kind) = @_;
    my $kind_num = $rkind{$kind};
    Carp::croak("no such value type: $kind") unless defined $kind_num;
    $ptr = $xsub->($kind_num);
  }
  bless {
    ptr   => $ptr,
    owner => $owner,
  }, $class;
});

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
