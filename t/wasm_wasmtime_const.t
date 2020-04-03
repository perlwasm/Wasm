use Test2::V0 -no_srand => 1;
use Wasm::Wasmtime;

foreach my $const (sort keys %Wasm::Wasmtime::)
{
  next unless $const =~ /^(WASM_|WASMTIME_)/;
  imported_ok $const;
  my $value = Wasm::Wasmtime->$const;
  is $value, D();
  note "$const = $value";
}

done_testing;
