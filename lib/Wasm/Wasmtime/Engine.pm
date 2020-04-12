package Wasm::Wasmtime::Engine;

use strict;
use warnings;
use Wasm::Wasmtime::FFI;
use Wasm::Wasmtime::Config;

# ABSTRACT: Wasmtime engine class
# VERSION

=head1 SYNOPSIS

# EXAMPLE: examples/synopsis/engine.pl

=head1 DESCRIPTION

B<WARNING>: WebAssembly and Wasmtime are a moving target and the interface for these modules
is under active development.  Use with caution.

This class represents the main WebAssembly engine.  It can optionally
be configured with a L<Wasm::Wasmtime::Config> object.

=cut

$ffi_prefix = 'wasm_engine_';
$ffi->type('opaque' => 'wasm_engine_t');

=head1 CONSTRUCTOR

=head2 new

 my $engine = Wasm::Wasmtime::Engine->new;
 my $engine = Wasm::Wasmtime::Engine->new(
   $config, # Wasm::Wasmtime::Config
 );

Creates a new instance of the engine class.

=cut

$ffi->attach( [ 'new_with_config' => 'new' ] => ['wasm_config_t'] => 'wasm_engine_t' => sub {
  my($xsub, $class, $config) = @_;
  $config ||= Wasm::Wasmtime::Config->new;
  bless {
    ptr => $xsub->(delete $config->{ptr}),
  }, $class;
});

$ffi->attach( [ 'delete' => 'DESTROY' ] => ['wasm_engine_t'] => sub {
  my($xsub, $self) = @_;
  $xsub->($self->{ptr}) if $self->{ptr};
});

1;

=head1 SEE ALSO

=over 4

=item L<Wasm>

=item L<Wasm::Wasmtime>

=back

