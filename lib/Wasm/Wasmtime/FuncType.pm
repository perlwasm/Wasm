package Wasm::Wasmtime::FuncType;

use strict;
use warnings;
use Wasm::Wasmtime::FFI;
use Wasm::Wasmtime::ValType;

# ABSTRACT: Wasmtime function type class
# VERSION

$ffi_prefix = 'wasm_functype_';
$ffi->type('opaque' => 'wasm_functype_t');

$ffi->attach( new => ['wasm_valtype_vec_t*', 'wasm_valtype_vec_t*'] => 'wasm_functype_t' => sub {
  my $xsub = shift;
  my $class = shift;
  my($ptr, $owner);
  if(ref $_[0])
  {
    # try not to think too much about all of the maps here
    my($params, $results) = map { my $rec = Wasm::Wasmtime::ValTypeVec->new; $rec->set($_) }
                            map { [map { delete $_->{ptr} } map { Wasm::Wasmtime::ValType->new($_) } @$_] } @_;
    $ptr = $xsub->($params, $results);
  }
  else
  {
    ($ptr, $owner) = @_;
  }
  bless {
    ptr   => $ptr,
    owner => $owner,
  }, $class;
});

$ffi->attach( params => ['wasm_functype_t'] => 'wasm_valtype_vec_t*' => sub {
  my($xsub, $self) = @_;
  $xsub->($self->{ptr})->to_list;
});

$ffi->attach( results => ['wasm_functype_t'] => 'wasm_valtype_vec_t*' => sub {
  my($xsub, $self) = @_;
  $xsub->($self->{ptr})->to_list;
});

$ffi->attach( [ delete => "DESTROY" ] => ['wasm_functype_t'] => sub {
  my($xsub, $self) = @_;
  if(defined $self->{ptr} && !defined $self->{owner})
  {
    $xsub->($self->{ptr});
  }
});

1;
