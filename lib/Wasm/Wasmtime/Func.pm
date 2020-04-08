package Wasm::Wasmtime::Func;

use strict;
use warnings;
use Wasm::Wasmtime::FFI;
use Wasm::Wasmtime::FuncType;

# ABSTRACT: Wasmtime function class
# VERSION

$ffi->mangler(sub { "wasm_func_$_[0]" });
$ffi->type('opaque' => 'wasm_func_t');

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

$ffi->attach( type => ['wasm_func_t'] => 'wasm_functype_t' => sub {
  my($xsub, $self) = @_;
  Wasm::Wasmtime::FuncType->new($xsub->($self->{ptr}), $self->{owner} || $self);
});

$ffi->attach( [ delete => "DESTROY" ] => ['wasm_func_t'] => sub {
  my($xsub, $self) = @_;
  if(defined $self->{ptr} && !defined $self->{owner})
  {
    $xsub->($self->{ptr});
  }
});

1;
