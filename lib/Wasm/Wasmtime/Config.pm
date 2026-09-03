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

=head2 wasm_multi_memory

 $config->wasm_multi_memory($bool);

Configures whether the wasm multi-memory proposal is enabled.

L<https://github.com/webassembly/multi-memory>

=head2 wasm_memory64

 $config->wasm_memory64($bool);

Configures whether the wasm memory64 proposal is enabled.

L<https://github.com/webassembly/memory64>

=head2 wasm_tail_call

 $config->wasm_tail_call($bool);

Configures whether the wasm tail call proposal is enabled.

L<https://github.com/webassembly/tail-call>

=head2 wasm_function_references

 $config->wasm_function_references($bool);

Configures whether the wasm typed function references proposal is enabled.

L<https://github.com/webassembly/function-references>

=head2 wasm_gc

 $config->wasm_gc($bool);

Configures whether the wasm garbage collection proposal is enabled.

L<https://github.com/webassembly/gc>

=head2 wasm_exceptions

 $config->wasm_exceptions($bool);

Configures whether the wasm exception handling proposal is enabled.

L<https://github.com/webassembly/exception-handling>

=head2 wasm_relaxed_simd

 $config->wasm_relaxed_simd($bool);

Configures whether the wasm relaxed SIMD proposal is enabled.

L<https://github.com/webassembly/relaxed-simd>

=head2 wasm_relaxed_simd_deterministic

 $config->wasm_relaxed_simd_deterministic($bool);

Configures whether the wasm relaxed SIMD proposal executes in its
deterministic mode.

=head2 wasm_custom_page_sizes

 $config->wasm_custom_page_sizes($bool);

Configures whether the wasm custom-page-sizes proposal is enabled.

L<https://github.com/webassembly/custom-page-sizes>

=head2 wasm_wide_arithmetic

 $config->wasm_wide_arithmetic($bool);

Configures whether the wasm wide-arithmetic proposal is enabled.

L<https://github.com/webassembly/wide-arithmetic>

=head2 wasm_branch_hinting

 $config->wasm_branch_hinting($bool);

Configures whether the wasm branch-hinting proposal is enabled.

L<https://github.com/WebAssembly/branch-hinting>

=head2 wasm_stack_switching

 $config->wasm_stack_switching($bool);

Configures whether the wasm stack-switching proposal is enabled.

L<https://github.com/WebAssembly/stack-switching>

=head2 wasm_component_model

 $config->wasm_component_model($bool);

Configures whether the WebAssembly component model is enabled.

=head2 wasm_component_model_async

 $config->wasm_component_model_async($bool);

Configures whether the async features of the component model are enabled.

=head2 wasm_component_model_async_stackful

 $config->wasm_component_model_async_stackful($bool);

Configures whether "stackful" async in the component model is enabled.

=head2 wasm_component_model_more_async_builtins

 $config->wasm_component_model_more_async_builtins($bool);

Configures whether additional async built-ins in the component model are
enabled.

=head2 wasm_component_model_map

 $config->wasm_component_model_map($bool);

Configures whether the C<map> type of the component model is enabled.

=head2 concurrency_support

 $config->concurrency_support($bool);

Configures whether component model concurrency support is enabled.

=head2 shared_memory

 $config->shared_memory($bool);

Configures whether shared linear memories may be created.

=head2 gc_support

 $config->gc_support($bool);

Enables or disables garbage collection support in Wasmtime entirely.

=head2 parallel_compilation

 $config->parallel_compilation($bool);

Configures whether Wasmtime compiles a module using multiple threads.

=head2 cranelift_nan_canonicalization

 $config->cranelift_nan_canonicalization($bool);

Configures whether cranelift replaces NaN values with a single canonical
value, for entirely deterministic execution.

=head2 memory_may_move

 $config->memory_may_move($bool);

Configures whether a linear memory is permitted to relocate (move its base
address) when it grows beyond L</memory_reservation>.

=head2 memory_init_cow

 $config->memory_init_cow($bool);

Configures whether linear memories are initialized with a copy-on-write
mapping of the module image.  Defaults to true.

=head2 native_unwind_info

 $config->native_unwind_info($bool);

Configures whether native unwind information (e.g. C<.eh_frame> on Linux) is
generated.  Defaults to true.

=head2 macos_use_mach_ports

 $config->macos_use_mach_ports($bool);

Configures whether, on macOS, Mach ports are used for exception handling
instead of traditional Unix signal handling.  Defaults to true.

=head2 signals_based_traps

 $config->signals_based_traps($bool);

Configures whether signal handlers (e.g. C<SIGSEGV> / C<SIGILL>) are used to
implement wasm traps.  Defaults to true.

=head2 memory_reservation_for_growth

 $config->memory_reservation_for_growth($size);

Configures the size, in bytes, of extra virtual memory reserved for a linear
memory to grow into after it has been relocated.

=cut

foreach my $prop (qw(
  cranelift_debug_verifier
  cranelift_nan_canonicalization
  debug_info
  epoch_interruption
  consume_fuel
  parallel_compilation
  concurrency_support
  gc_support
  shared_memory
  memory_may_move
  memory_init_cow
  native_unwind_info
  macos_use_mach_ports
  signals_based_traps
  wasm_bulk_memory
  wasm_reference_types
  wasm_function_references
  wasm_gc
  wasm_exceptions
  wasm_multi_value
  wasm_multi_memory
  wasm_memory64
  wasm_tail_call
  wasm_simd
  wasm_relaxed_simd
  wasm_relaxed_simd_deterministic
  wasm_custom_page_sizes
  wasm_wide_arithmetic
  wasm_branch_hinting
  wasm_stack_switching
  wasm_threads
  wasm_component_model
  wasm_component_model_async
  wasm_component_model_async_stackful
  wasm_component_model_more_async_builtins
  wasm_component_model_map
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

foreach my $prop (qw( memory_reservation memory_guard_size memory_reservation_for_growth ))
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

=head2 cranelift_regalloc_algorithm

 $config->cranelift_regalloc_algorithm($algorithm);

Configure the register allocation algorithm used by the cranelift code
generator.

Acceptable values for C<$algorithm> are:

=over 4

=item C<backtracking>

=item C<single_pass>

=back

=cut

my %cranelift_regalloc_algorithm = (
  backtracking => 0,
  single_pass  => 1,
);

$ffi->attach( ['wasmtime_config_cranelift_regalloc_algorithm_set' => 'cranelift_regalloc_algorithm' ] => ['wasm_config_t', 'uint8' ] => 'void' => sub {
  my($xsub, $self, $value) = @_;
  Carp::croak("unknown cranelift_regalloc_algorithm: $value") unless defined $cranelift_regalloc_algorithm{$value};
  $xsub->($self, $cranelift_regalloc_algorithm{$value});
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

=head2 target

 $config->target($triple);

Configures the target triple that this configuration will produce machine
code for (defaults to the native host).  Setting this also disables inference
of the native CPU features of the host; re-enable specific ones with
L</cranelift_flag_enable> / L</cranelift_flag_set>.

=cut

$ffi->attach( [ 'wasmtime_config_target_set' => 'target' ] => [ 'wasm_config_t', 'string' ] => 'wasmtime_error_t' => sub {
  my($xsub, $self, $value) = @_;
  Carp::croak("undef passed in as target") unless defined $value;
  if(my $error = $xsub->($self, $value))
  {
    Carp::croak($error->message);
  }
  $self;
});

=head2 cranelift_flag_enable

 $config->cranelift_flag_enable($flag);

Enables a target-specific boolean flag in cranelift (for example C<has_sse42>
on x86_64 hosts).

=cut

$ffi->attach( [ 'wasmtime_config_cranelift_flag_enable' => 'cranelift_flag_enable' ] => [ 'wasm_config_t', 'string' ] => 'void' => sub {
  my($xsub, $self, $value) = @_;
  Carp::croak("undef passed in as cranelift flag") unless defined $value;
  $xsub->($self, $value);
  $self;
});

=head2 cranelift_flag_set

 $config->cranelift_flag_set($key, $value);

Sets a target-specific cranelift flag to the given value.

=cut

$ffi->attach( [ 'wasmtime_config_cranelift_flag_set' => 'cranelift_flag_set' ] => [ 'wasm_config_t', 'string', 'string' ] => 'void' => sub {
  my($xsub, $self, $key, $value) = @_;
  Carp::croak("undef passed in as cranelift flag key")   unless defined $key;
  Carp::croak("undef passed in as cranelift flag value") unless defined $value;
  $xsub->($self, $key, $value);
  $self;
});

1;

=head1 SEE ALSO

=over 4

=item L<Wasm>

=item L<Wasm::Wasmtime>

=back

=cut
