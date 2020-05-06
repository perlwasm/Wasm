package Wasm::Wasmtime::ExternType;

use strict;
use warnings;
use Wasm::Wasmtime::FFI;
use Wasm::Wasmtime::FuncType;
use Wasm::Wasmtime::GlobalType;
use Wasm::Wasmtime::TableType;
use Wasm::Wasmtime::MemoryType;

# ABSTRACT: Wasmtime extern type class
# VERSION

=head1 DESCRIPTION

This is a private class.  The C<.pm> file for it may be removed in the future.

=cut

$ffi_prefix = 'wasm_externtype_';
$ffi->load_custom_type('::PtrObject' => 'wasm_externtype_t' => __PACKAGE__);

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

sub _cast_body
{
  my($xsub, $self) = @_;
  my $type = $xsub->($self);
  return undef unless $type;
  $type->{owner} = $self->{owner} || $self if $type;
  $type;
}

sub kind { $kind{shift->kind_num} }

$ffi->attach( [ kind => 'kind_num' ] => ['wasm_externtype_t'] => 'uint8');

$ffi->attach( "as_${_}type"   => ['wasm_externtype_t'] => "wasm_${_}type_t"   => \&_cast_body)
  for qw( func global table memory );

_generate_destroy();

1;
