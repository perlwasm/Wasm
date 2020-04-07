use Test2::V0 -no_srand => 1;
use Wasm::NWasmtime;

subtest 'exports' => sub {

  subtest 'constants' => sub {
    foreach my $const (sort keys %Wasm::NWasmtime::)
    {
      next unless $const =~ /^(WASM_|WASMTIME_)/;
      imported_ok $const;
      my $value = Wasm::Wasmtime->$const;
      is $value, D();
      note "$const = $value";
    }
  };

  subtest 'functions' => sub {
    foreach my $func (sort keys %Wasm::NWasmtime::)
    {
      next unless $func =~ /^(wasm_|wasmtime_)/;
      imported_ok $func;
    }

  };
};

subtest 'wat2wasm' => sub {

  my $wasm = wasmtime_wat2wasm '(module)';
  is $wasm, T(), 'jit compiles simple wat';

  is dies { wasmtime_wat2wasm 'f00f' }, match qr/wat2wasm error/;
};

done_testing;
