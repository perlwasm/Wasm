package Wasm::Wasmtime::Config;

use strict;
use warnings;
use 5.008004;
use Wasm::Wasmtime::FFI;
use Carp ();

# ABSTRACT: Global configuration for Wasm::Wasmtime::Engine
# VERSION

=head1 SYNOPSIS

# EXAMPLE: examples/synopsis/config.pl

=head1 DESCRIPTION

B<WARNING>: WebAssembly and Wasmtime are a moving target and the interface for these modules
is under active development.  Use with caution.

This class contains the configuration for L<Wasm::Wasmtime::Engine>
class.  Each instance of the config class should only be used once.

=cut

$ffi_prefix = 'wasm_config_';
$ffi->load_custom_type('::PtrObject' => 'wasm_config_t' => __PACKAGE__);

=head1 CONSTRUCTOR

=head2 new

 my $config = Wasm::Wasmtime::Config->new;

Create a new instance of the config class.

=cut

$ffi->attach( new => [] => 'wasm_config_t' );

_generate_destroy('wasm_config_delete');

=head1 METHODS

=head2 debug_info

 $config->debug_info($bool);

Configures whether DWARF debug information is emitted for the generated
code. This can improve profiling and the debugging experience.

=head2 epoch_interruption

 $config->epoch_interruption($bool);

Configures whether execution of WebAssembly will "yield" when a deadline is
reached.  This replaces the old (removed) C<interruptable> configuration.

=head2 consume_fuel

 $config->consume_fuel($bool);

Whether or not fuel is enabled for generated code.  When enabled a store must
be given fuel with C<< $store->set_fuel >> before WebAssembly can execute.

=head2 max_wasm_stack

 $config->max_wasm_stack($size);

Configures the maximum amount of native stack space available to executing WebAssembly code

=head2 wasm_threads

 $config->wasm_threads($bool);

Configures whether the wasm threads proposal is enabled

L<https://github.com/webassembly/threads>

=head2 wasm_reference_types

 $config->wasm_reference_types($bool);

Configures whether the wasm reference types proposal is enabled.

L<https://github.com/webassembly/reference-types>

=head2 wasm_simd

 $config->wasm_simd($bool);

Configures whether the wasm SIMD proposal is enabled.

L<https://github.com/webassembly/simd>

=head2 wasm_bulk_memory

 $config->wasm_bulk_memory($bool);

Configures whether the wasm bulk memory proposal is enabled.

L<https://github.com/webassembly/bulk-memory>

=head2 wasm_multi_value

 $config->wasm_multi_value($bool)

Configures whether the wasm multi value proposal is enabled.

L<https://github.com/webassembly/multi-value>

=cut

foreach my $prop (qw(
  cranelift_debug_verifier
  debug_info
  epoch_interruption
  consume_fuel
  wasm_bulk_memory
  wasm_reference_types
  wasm_multi_value
  wasm_simd
  wasm_threads
))
{
  $ffi->attach( [ "wasmtime_config_${prop}_set" => $prop ] => [ 'wasm_config_t', 'bool' ] => 'void' => sub {
    my($xsub, $self, $value) = @_;
    $xsub->($self, $value);
    $self;
  });
}

foreach my $prop (qw(
  max_wasm_stack
))
{
  $ffi->attach( [ "wasmtime_config_${prop}_set" => $prop ] => [ 'wasm_config_t', 'size_t' ] => 'void' => sub {
    my($xsub, $self, $value) = @_;
    $xsub->($self, $value);
    $self;
  });
}

=head2 memory_reservation

 $config->memory_reservation($size);

Configures the size, in bytes, of virtual memory reservation for each linear
memory.  Setting this (and L</memory_guard_size>) to C<0> disables the large
C<PROT_NONE> reservations that can trip C<ulimit -v> limits.  Replaces the
old (removed) C<static_memory_maximum_size>.

=head2 memory_guard_size

 $config->memory_guard_size($size);

Configures the size, in bytes, of the guard region placed after each linear
memory.  Replaces the old (removed) C<static_memory_guard_size> /
C<dynamic_memory_guard_size>.

=cut

foreach my $prop (qw( memory_reservation memory_guard_size ))
{
  $ffi->attach( [ "wasmtime_config_${prop}_set" => $prop ] => [ 'wasm_config_t', 'uint64' ] => 'void' => sub {
    my($xsub, $self, $value) = @_;
    $xsub->($self, $value);
    $self;
  });
}

=head2 strategy

 $config->strategy($strategy);

Configures the compilation strategy used for wasm code.

Acceptable values for C<$strategy> are:

=over 4

=item C<auto>

=item C<cranelift>

=item C<winch>

=back

=cut

my %strategy = (
  auto      => 0,
  cranelift => 1,
  winch     => 2,
);

$ffi->attach( [ 'wasmtime_config_strategy_set' => 'strategy' ] => [ 'wasm_config_t', 'uint8' ] => 'void' => sub {
  my($xsub, $self, $value) = @_;
  Carp::croak("unknown strategy: $value") unless defined $strategy{$value};
  $xsub->($self, $strategy{$value});
  $self;
});

=head2 cranelift_opt_level

 $config->cranelift_opt_level($level);

Configure the cranelift optimization level:

Acceptable values for C<$level> are:

=over 4

=item C<none>

=item C<speed>

=item C<speed_and_size>

=back

=cut

my %cranelift_opt_level = (
  none => 0,
  speed => 1,
  speed_and_size => 2,
);

$ffi->attach( ['wasmtime_config_cranelift_opt_level_set' => 'cranelift_opt_level' ] => ['wasm_config_t', 'uint8' ] => 'void' => sub {
  my($xsub, $self, $value) = @_;
  Carp::croak("unknown cranelift_opt_level: $value") unless defined $cranelift_opt_level{$value};
  $xsub->($self, $cranelift_opt_level{$value});
  $self;
});

=head2 profiler

 $config->profiler($profiler);

Configure the profiler.

Acceptable values for C<$profiler> are:

=over 4

=item C<none>

=item C<jitdump>

=item C<vtune>

=item C<perfmap>

=back

=cut

my %profiler = (
  none    => 0,
  jitdump => 1,
  vtune   => 2,
  perfmap => 3,
);

$ffi->attach( ['wasmtime_config_profiler_set' => 'profiler' ] => ['wasm_config_t', 'uint8'] => 'void' => sub {
  my($xsub, $self, $value) = @_;
  Carp::croak("unknown profiler: $value") unless defined $profiler{$value};
  $xsub->($self, $profiler{$value});
  $self;
});

=head2 cache_config_load

 $config->cache_config_load($toml_config);

Path to the cache configuration TOML file.

=head2 cache_config_default

 $config->cache_config_default;

Enable the default caching configuration.

=cut

$ffi->attach( [ 'wasmtime_config_cache_config_load' => 'cache_config_load' ] => [ 'wasm_config_t', 'string' ] => 'wasmtime_error_t' => sub {
  my($xsub, $self, $value) = @_;
  Carp::croak("undef passed in as cache config") unless defined $value;
  if(my $error = $xsub->($self, $value))
  {
    Carp::croak($error->message);
  }
  $self;
});

$ffi->attach( [ 'wasmtime_config_cache_config_load' => 'cache_config_default' ] => [ 'wasm_config_t', 'string' ] => 'wasmtime_error_t' => sub {
  my($xsub, $self) = @_;
  if(my $error = $xsub->($self, undef))
  {
    Carp::croak($error->message);
  }
  $self;
});

1;

=head1 SEE ALSO

=over 4

=item L<Wasm>

=item L<Wasm::Wasmtime>

=back

=cut
