use Test2::V0 -no_srand => 1;
use Wasm::Wasmtime;

is(
  Wasm::Wasmtime::ByteVec->new("frooble"),
  object {
    call size => 7;
    call data => D();
    call to_string => "frooble";
  },
  "basic string bytevec",
);

is(
  Wasm::Wasmtime::ByteVec->new("frooble")->copy,
  object {
    call size => 7;
    call data => D();
    call to_string => "frooble";
  },
  "basic string bytevec",
);

is(
  Wasm::Wasmtime::ByteVec->new,
  object {
    call size => 0;
    call data => D();
    call to_string => "";
  },
  "empty vector",
);

done_testing;
