use 5.008004;
use Test2::V0 -no_srand => 1;
use Wasm::Wasmtime::Wat2Wasm;

imported_ok 'wat2wasm';

my $binary;

is(
  $binary = wat2wasm('(module)'),
  D(),
  'okay with good module',
);

is(
  dies { wat2wasm('f00f') },
  match qr/wat2wasm error/,
  'dies with bad input',
);

use YAML();
note YAML::Dump(\$binary);

done_testing;
