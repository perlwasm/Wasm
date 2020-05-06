package Wasm::Wasmtime::Extern;

use strict;
use warnings;
use Wasm::Wasmtime::FFI;
use Wasm::Wasmtime::Func;
use Wasm::Wasmtime::Global;
use Wasm::Wasmtime::Table;
use Wasm::Wasmtime::Memory;
use Wasm::Wasmtime::ExternType;

# ABSTRACT: Wasmtime extern class
# VERSION

=head1 DESCRIPTION

This is a private class.  The C<.pm> file for it may be removed in the future.

=cut

$ffi_prefix = 'wasm_extern_';
$ffi->load_custom_type('::PtrObject' => 'wasm_extern_t' => __PACKAGE__);

sub new
{
  my($class, $ptr, $owner) = @_;
  bless {
    ptr   => $ptr,
    owner => $owner,
  }, $class;
}

sub _cast_body
{
  my($xsub, $self) = @_;
  my $extern = $xsub->($self);
  return undef unless $extern;
  $extern->{owner} = $self->{owner} || $self;
  $extern;
}

$ffi->attach( type => ['wasm_extern_t'] => 'wasm_externtype_t' => sub {
  my($xsub, $self) = @_;
  $xsub->($self);
});

my %kind = (
  0 => 'func',
  1 => 'global',
  2 => 'table',
  3 => 'memory',
);

sub kind { $kind{shift->kind_num} }

$ffi->attach( [ kind => 'kind_num' ] => ['wasm_extern_t'] => 'uint8');

$ffi->attach( "as_$_" => ['wasm_extern_t'] => "wasm_${_}_t" => \&_cast_body)
  for qw( func global table memory );

_generate_destroy();
_generate_vec_class();

1;
