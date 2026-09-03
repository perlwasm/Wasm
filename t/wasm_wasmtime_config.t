use 5.008004;
use Test2::V0 -no_srand => 1;
use Wasm::Wasmtime::Config;
use File::Glob qw( bsd_glob );

my $config = Wasm::Wasmtime::Config->new;
isa_ok $config, 'Wasm::Wasmtime::Config';

foreach my $prop (qw(
  debug_info
  wasm_threads
  wasm_reference_types
  wasm_simd
  wasm_bulk_memory
  wasm_multi_value
  epoch_interruption
  consume_fuel
  cranelift_debug_verifier
))
{
  $config->$prop(0);
  $config->$prop(1);
  pass $prop;
}

$config->max_wasm_stack(1024 * 1024);
pass 'max_wasm_stack';

foreach my $strategy (qw( auto cranelift winch ))
{
  if(my $e = dies { $config->strategy($strategy) })
  {
    is($e, mismatch qr/unknown strategy:/, "strategy($strategy) = fail");
    note "exception: $e";
  }
  else
  {
    pass "strategy($strategy) = ok";
  }
}

is
  dies { $config->strategy('foo') },
  match qr/unknown strategy: foo/,
  'strategy: unknown strategy'
;

foreach my $cranelift_opt_level (qw( none speed speed_and_size ))
{
  $config->cranelift_opt_level($cranelift_opt_level);
  pass "cranelift_opt_level($cranelift_opt_level) = ok";
}

is
  dies { $config->cranelift_opt_level('foo') },
  match qr/unknown cranelift_opt_level: foo/,
  'cranelift_opt_level: unknown cranelift_opt_level'
;

foreach my $profiler (qw( none jitdump vtune perfmap ))
{
  if(my $e = dies { $config->profiler($profiler) })
  {
    is($e, mismatch qr/unknown profiler:/, "profiler($profiler) = fail");
    note "exception: $e";
  }
  else
  {
    pass "profiler($profiler) = ok";
  }
}

is
  dies { $config->profiler('foo') },
  match qr/unknown profiler: foo/,
  'profiler: unknown profiler'
;

foreach my $prop (qw( memory_reservation memory_guard_size ))
{
  $config->$prop(0);
  $config->$prop(1024 * 1024);
  pass $prop;
}

unlink $_ for bsd_glob('jit-*.dump');

done_testing;
