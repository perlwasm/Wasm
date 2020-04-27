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

=head1 SYNOPSIS

# EXAMPLE: examples/synopsis/extern.pl

=head1 DESCRIPTION

This class represents an object exported from L<Wasm::Wasmtime::Instance>.

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

=head1 METHODS

=head2 type

 my $externtype = $extern->type;

Returns the L<Wasm::Wasmtime::ExternType> for this extern.

=cut

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

sub kind { $kind{shift->kind_num} }

=head2 kind_num

 my $kind = $extern->kind_num;

Returns the kind of extern as the internal integer used by Wasmtime.

=cut

$ffi->attach( [ kind => 'kind_num' ] => ['wasm_extern_t'] => 'uint8');

=head2 as_func

 my $func = $extern->as_func;

If the extern is a C<func>, returns its L<Wasm::Wasmtime::Func>.
Otherwise returns C<undef>.

=cut

$ffi->attach( as_func => ['wasm_extern_t'] => 'wasm_func_t' => sub {
  my($xsub, $self) = @_;
  my $func = $xsub->($self);
  return unless $func;
  $func->{owner} = $self->{owner} || $self;
  $func;
});

=head2 as_global

 my $global = $extern->as_global;

If the extern is a C<global>, returns its L<Wasm::Wasmtime::Global>.
Otherwise returns C<undef>.

=cut

$ffi->attach( as_global => ['wasm_extern_t'] => 'wasm_global_t' => sub {
  my($xsub, $self) = @_;
  my $ptr = $xsub->($self);
  return undef unless $ptr;
  Wasm::Wasmtime::Global->new($ptr, $self->{owner} || $self);
});

=head2 as_table

 my $table = $extern->as_table;

If the extern is a C<table>, returns its L<Wasm::Wasmtime::Table>.
Otherwise returns C<undef>.

=cut

$ffi->attach( as_table => ['wasm_extern_t'] => 'wasm_table_t' => sub {
  my($xsub, $self) = @_;
  my $ptr = $xsub->($self);
  return undef unless $ptr;
  Wasm::Wasmtime::Table->new($ptr, $self->{owner} || $self);
});

=head2 as_memory

 my $memory = $extern->as_memory;

If the extern is a C<memory>, returns its L<Wasm::Wasmtime::Memory>.
Otherwise returns C<undef>.

=cut

$ffi->attach( as_memory => ['wasm_extern_t'] => 'wasm_memory_t' => sub {
  my($xsub, $self) = @_;
  my $ptr = $xsub->($self);
  return undef unless $ptr;
  Wasm::Wasmtime::Memory->new($ptr, $self->{owner} || $self);
});

_generate_destroy();
_generate_vec_class();

1;

=head1 SEE ALSO

=over 4

=item L<Wasm>

=item L<Wasm::Wasmtime>

=back

