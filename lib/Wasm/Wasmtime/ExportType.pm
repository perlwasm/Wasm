package Wasm::Wasmtime::ExportType;

use strict;
use warnings;
use Wasm::Wasmtime::FFI;
use Wasm::Wasmtime::ExternType;

# ABSTRACT: Wasmtime export type class
# VERSION

$ffi->mangler(sub { "wasm_exporttype_$_[0]" });
$ffi->type('opaque' => 'wasm_exporttype_t');

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

$ffi->attach( name => ['wasm_exporttype_t'] => 'wasm_byte_vec_t*' => sub {
  my($xsub, $self) = @_;
  my $name = $xsub->($self->{ptr});
  $name->get;
});

$ffi->attach( type => ['wasm_exporttype_t'] => 'wasm_externtype_t' => sub {
  my($xsub, $self) = @_;
  Wasm::Wasmtime::ExternType->new(
    $xsub->($self->{ptr}),
    $self->{owner} || $self,
  );
});

$ffi->attach( [ delete => "DESTROY" ] => ['wasm_exporttype_t'] => sub {
  my($xsub, $self) = @_;
  if(defined $self->{ptr} && !defined $self->{owner})
  {
    $xsub->($self->{ptr});
  }
});

{ package Wasm::Wasmtime::ExportTypeVec;
  use base qw( Wasm::Wasmtime::Vec );
  use Wasm::Wasmtime::FFI;

  $ffi->mangler(sub { "wasm_exporttype_vec_$_[0]" });
  $ffi->type('record(Wasm::Wasmtime::ExportTypeVec)' => 'wasm_exporttype_vec_t');
  $ffi->attach([delete => 'DESTROY'] => ['wasm_exporttype_vec_t*'] => sub {
    my($xsub, $self) = @_;
    $xsub->($self);
    $self->SUPER::DESTROY;
  });
}

1;
