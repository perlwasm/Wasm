package Wasm::Wasmtime::FuncType;

use strict;
use warnings;
use Wasm::Wasmtime::FFI;
use Wasm::Wasmtime::ValType;

# ABSTRACT: Wasmtime function type class
# VERSION

$ffi->mangler(sub { "wasm_functype_$_[0]" });
$ffi->type('opaque' => 'wasm_functype_t');

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
