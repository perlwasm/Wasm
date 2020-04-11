package Wasm::Wasmtime::Extern;

use strict;
use warnings;
use Wasm::Wasmtime::FFI;
use Wasm::Wasmtime::Func;
use Wasm::Wasmtime::Memory;
use Wasm::Wasmtime::ExternType;

# ABSTRACT: Wasmtime extern class
# VERSION

=head1 SYNOPSIS

# EXAMPLE: examples/synopsis/extern.pl

=head1 DESCRIPTION

This class represents an object exported from L<Wasm::Wasmtime::Instance>.

=cut

$ffi_prefix = 'wasm_extern_';
$ffi->type('opaque' => 'wasm_extern_t');

sub new
{
  my($class, $ptr, $owner) = @_;
  bless {
    ptr   => $ptr,
    owner => $owner,
  }, $class;
}

=head1 METHODS

=head2 type

 my $externtype = $extern->type;

Returns the L<Wasm::Wasmtime::ExternType> for this extern.

=cut

$ffi->attach( type => ['wasm_extern_t'] => 'wasm_externtype_t' => sub {
  my($xsub, $self) = @_;
  Wasm::Wasmtime::ExternType->new($xsub->($self->{ptr}), undef);
});

my %kind = (
  0 => 'func',
  1 => 'global',
  2 => 'table',
  3 => 'memory',
);

=head2 kind

 my $kind = $extern->kind;

Returns the kind of extern.  Should be one of:

=over 4

=item C<func>

=item C<global>

=item C<table>

=item C<memory>

=back

=cut

$ffi->attach( kind => ['wasm_extern_t'] => 'uint8' => sub {
  my($xsub, $self) = @_;
  $kind{$xsub->($self->{ptr})};
});

=head2 kind_num

 my $kind = $extern->kind_num;

Returns the kind of extern as the internal integer used by Wasmtime.

=cut

$ffi->attach( [ kind => 'kind_num' ] => ['wasm_extern_t'] => 'uint8' => sub {
  my($xsub, $self) = @_;
  $xsub->($self->{ptr});
});

=head2 as_func

 my $func = $extern->as_func;

If the extern is a C<func>, returns its L<Wasm::Wasmtime::Func>.
Otherwise returns C<undef>.

=cut

$ffi->attach( as_func => ['wasm_extern_t'] => 'wasm_func_t' => sub {
  my($xsub, $self) = @_;
  my $ptr = $xsub->($self->{ptr});
  return undef unless $ptr;
  Wasm::Wasmtime::Func->new($ptr, $self->{owner} || $self);
});

=head2 as_memory

 my $memory = $extern->as_memory;

If the extern is a C<memory>, returns its L<Wasm::Wasmtime::Memory>.
Otherwise returns C<undef>.

=cut

$ffi->attach( as_memory => ['wasm_extern_t'] => 'wasm_memory_t' => sub {
  my($xsub, $self) = @_;
  my $ptr = $xsub->($self->{ptr});
  return undef unless $ptr;
  Wasm::Wasmtime::Memory->new($ptr, $self->{owner} || $self);
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
