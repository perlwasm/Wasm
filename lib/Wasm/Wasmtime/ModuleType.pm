package Wasm::Wasmtime::ModuleType;

use strict;
use warnings;
use 5.008004;
use Wasm::Wasmtime::FFI;
use Wasm::Wasmtime::Module::Exports;
use Wasm::Wasmtime::Module::Imports;
use Wasm::Wasmtime::ImportType;
use Wasm::Wasmtime::ExportType;

# ABSTRACT: Wasmtime context class
# VERSION

$ffi_prefix = 'wasmtime_moduletype_';
$ffi->load_custom_type('::PtrObject' => 'wasmtime_moduletype_t' => __PACKAGE__);

=head1 SYNOPSIS

# TODO

=head1 DESCRIPTION

TODO

=head1 METHODS

=head2 imports

# TODO

=head2 exports

# TODO

=cut

if(_ver ne '0.27.0')
{
  $ffi->attach( [ imports => '_imports' ] => ['wasmtime_moduletype_t','wasm_importtype_vec_t*'] => sub {
    my($xsub, $self) = @_;
    my $imports = Wasm::Wasmtime::ImportTypeVec->new;
    $xsub->($self, $imports);
    $imports->to_list;
  });

  $ffi->attach( [ exports => '_exports' ] => ['wasmtime_moduletype_t','wasm_exporttype_vec_t*'] => sub {
    my($xsub, $self) = @_;
    my $exports = Wasm::Wasmtime::ExportTypeVec->new;
    $xsub->($self, $exports);
    $exports->to_list;
  });

  sub exports
  {
    Wasm::Wasmtime::Module::Exports->new(shift);
  }

  sub imports
  {
    Wasm::Wasmtime::Module::Imports->new(shift);
  }

  _generate_destroy();
}

1;
