package Wasm::Wasmtime::Engine;

use strict;
use warnings;
use 5.008004;
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
$ffi->load_custom_type('::PtrObject' => 'wasm_engine_t' => __PACKAGE__ );

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
  if(defined $ENV{PERL_WASM_WASMTIME_MEMORY})
  {
    my($static_memory_maximum_size, $static_memory_guard_size, $dynamic_memory_guard_size) = split /:/, $ENV{PERL_WASM_WASMTIME_MEMORY};
    $config->static_memory_maximum_size($static_memory_maximum_size);
    $config->static_memory_guard_size($static_memory_guard_size);
    $config->dynamic_memory_guard_size($dynamic_memory_guard_size);
  }
  my $self = $xsub->($config),
  delete $config->{ptr};
  $self;
});

_generate_destroy();

1;

=head1 SEE ALSO

=over 4

=item L<Wasm>

=item L<Wasm::Wasmtime>

=back

=cut
