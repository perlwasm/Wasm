package Wasm::Wasmtime::ExternType;

use strict;
use warnings;
use Wasm::Wasmtime::FFI;
use Wasm::Wasmtime::FuncType;

# ABSTRACT: Wasmtime extern type class
# VERSION

$ffi->mangler(sub { "wasm_externtype_$_[0]" });
$ffi->type('opaque' => 'wasm_externtype_t');

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
  0 => 'func',
  1 => 'global',
  2 => 'table',
  3 => 'memory',
);

$ffi->attach( kind => ['wasm_externtype_t'] => 'uint8' => sub {
  my($xsub, $self) = @_;
  $kind{$xsub->($self->{ptr})};
});

$ffi->attach( as_functype => ['wasm_externtype_t'] => 'wasm_functype_t' => sub {
  my($xsub, $self) = @_;
  my $ptr = $xsub->($self->{ptr});
  $ptr ? Wasm::Wasmtime::FuncType->new($ptr, $self->{owner} || $self) : undef;
});

$ffi->attach( [ delete => "DESTROY" ] => ['wasm_externtype_t'] => sub {
  my($xsub, $self) = @_;
  if(defined $self->{ptr} && !defined $self->{owner})
  {
    $xsub->($self->{ptr});
  }
});

1;
