package Wasm::Wasmtime::ExternType;

use strict;
use warnings;
use Wasm::Wasmtime::FFI;
use Wasm::Wasmtime::FuncType;
use Wasm::Wasmtime::MemoryType;

# ABSTRACT: Wasmtime extern type class
# VERSION

=head1 SYNOPSIS

# EXAMPLE: examples/synopsis/externtype.pl

=head1 DESCRIPTION

This class represents an extern type.  This class cannot be created independently, but can be
retrieved from the L<Wasm::Wasmtime::Module> class.

=cut

$ffi_prefix = 'wasm_externtype_';
$ffi->type('opaque' => 'wasm_externtype_t');

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

=head1 METHODS

=head2 kind

 my $kind = $externtype->kind;

Returns the kind of extern type.  Should be one of:

=over 4

=item C<func>

=item C<global>

=item C<table>

=item C<memory>

=back

=cut

$ffi->attach( kind => ['wasm_externtype_t'] => 'uint8' => sub {
  my($xsub, $self) = @_;
  $kind{$xsub->($self->{ptr})};
});

=head2 kind_num

 my $kind = $externtype->kind_num;

Returns the kind of extern type as the internal integer code.

=cut

$ffi->attach( [ kind => 'kind_num' ] => ['wasm_externtype_t'] => 'uint8' => sub {
  my($xsub, $self) = @_;
  $xsub->($self->{ptr});
});

=head2 as_functype

 my $functype = $externtype->as_functype;

If the extern type is a function, returns the L<Was::Wasmtime::FuncType> for it.
Otherwise returns C<undef>.

=cut

$ffi->attach( as_functype => ['wasm_externtype_t'] => 'wasm_functype_t' => sub {
  my($xsub, $self) = @_;
  my $ptr = $xsub->($self->{ptr});
  $ptr ? Wasm::Wasmtime::FuncType->new($ptr, $self->{owner} || $self) : undef;
});

=head2 as_memorytype

 my $memorytype = $externtype->as_memorytype;

If the extern type is a memory object, returns the L<Was::Wasmtime::MemoryType> for it.
Otherwise returns C<undef>.

=cut

$ffi->attach( as_memorytype => ['wasm_externtype_t'] => 'wasm_memorytype_t' => sub {
  my($xsub, $self) = @_;
  my $ptr = $xsub->($self->{ptr});
  $ptr ? Wasm::Wasmtime::MemoryType->new($ptr, $self->{owner} || $self) : undef;
});

$ffi->attach( [ delete => "DESTROY" ] => ['wasm_externtype_t'] => sub {
  my($xsub, $self) = @_;
  if(defined $self->{ptr} && !defined $self->{owner})
  {
    $xsub->($self->{ptr});
  }
});

1;

=head1 SEE ALSO

=over 4

=item L<Wasm>

=item L<Wasm::Wasmtime>

=back

