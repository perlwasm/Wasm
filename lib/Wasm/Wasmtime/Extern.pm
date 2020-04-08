package Wasm::Wasmtime::Extern;

use strict;
use warnings;
use Wasm::Wasmtime::FFI;
use Wasm::Wasmtime::Func;
use Wasm::Wasmtime::ExternType;
use overload
  '&{}' => sub { my $self = shift; sub { $self->call(@_) } },
  bool => sub { 1 },
  fallback => 1;

# ABSTRACT: Wasmtime extern class
# VERSION

$ffi->mangler(sub { "wasm_extern_$_[0]" });
$ffi->type('opaque' => 'wasm_extern_t');

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

=head1 METHODS

=head2 call

=cut

sub call
{
  my $self = shift;
  $self->as_func->call(@_);
}

$ffi->attach( type => ['wasm_extern_t'] => 'wasm_externtype_t' => sub {
  my($xsub, $self) = @_;
  Wasm::Wasmtime::ExternType->new($xsub->($self->{ptr}), undef);
});

$ffi->attach( as_func => ['wasm_extern_t'] => 'wasm_func_t' => sub {
  my($xsub, $self) = @_;
  my $ptr = $xsub->($self->{ptr});
  return undef unless $ptr;
  Wasm::Wasmtime::Func->new($ptr, $self->{owner} || $self);
});

$ffi->attach( [ delete => "DESTROY" ] => ['wasm_extern_t'] => sub {
  my($xsub, $self) = @_;
  if(defined $self->{ptr} && !defined $self->{owner})
  {
    $xsub->($self->{ptr});
  }
});

_generate_vec_class();

1;
