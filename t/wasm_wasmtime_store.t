use 5.008004;
use Test2::V0 -no_srand => 1;
use Wasm::Wasmtime::Engine;
use Wasm::Wasmtime::Store;

subtest 'basic' => sub {

  my $warnings = 0;
  local $SIG{__WARN__} = sub {
    my $message = shift;
    if($message =~ /^Calling gc on a store directly is deprecated, please use \$store->context->gc instead/)
    {
      note "warning: $message";
      $warnings++;
    }
    else
    {
      warn $message;
    }
  };

  is(
    Wasm::Wasmtime::Store->new,
    object {
      call ['isa','Wasm::Wasmtime::Store'] => T();
      call engine => object {
        call ['isa','Wasm::Wasmtime::Engine'] => T();
      };
      call gc => U();
      call context => object {
        call ['isa','Wasm::Wasmtime::Context'] => T();
          call gc => U();
      };
    },
    'default engine',
  );

  is $warnings, 1, 'expected warnings';
  $warnings=0;

  is(
    Wasm::Wasmtime::Store->new(Wasm::Wasmtime::Engine->new),
    object {
      call ['isa','Wasm::Wasmtime::Store'] => T();
      call engine => object {
        call ['isa','Wasm::Wasmtime::Engine'] => T();
      };
      call gc => U();
      call context => object {
        call ['isa','Wasm::Wasmtime::Context'] => T();
          call gc => U();
      };
    },
    'explicit engine',
  );

  is $warnings, 1, 'expected warnings';
  $warnings=0;
};

done_testing;
