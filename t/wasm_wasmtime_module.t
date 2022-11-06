use 5.008004;
use Test2::V0 -no_srand => 1;
use lib 't/lib';
use Test2::Tools::Wasm;
use Wasm::Wasmtime::Engine;
use Wasm::Wasmtime::Store;
use Wasm::Wasmtime::Module;
use Wasm::Wasmtime::Wat2Wasm;

my $wasm_binary = "\0asm\x01\0\0\0";

subtest 'validate' => sub {

  is(
    scalar(Wasm::Wasmtime::Module->validate($wasm_binary)),
    T(),
    'validate good raw',
  );

  is(
    scalar(Wasm::Wasmtime::Module->validate(wat2wasm('(module)'))),
    T(),
    'validate good from wat2wasm',
  );

  is(
    [Wasm::Wasmtime::Module->validate(wat2wasm('(module)'))],
    array {
      item T();
      item '';
      end;
    },
    'validate good, list context',
  );

  is(
    scalar(Wasm::Wasmtime::Module->validate( wat => '(module)' )),
    T(),
    'validate good, key wat',
  );

  is(
    scalar(Wasm::Wasmtime::Module->validate(Wasm::Wasmtime::Store->new, wat2wasm('(module)'))),
    T(),
    'validate good with store',
  );

  is(
    scalar(Wasm::Wasmtime::Module->validate(Wasm::Wasmtime::Store->new, wat => '(module)')),
    T(),
    'validate good with store, key wat',
  );

  is(
    scalar(Wasm::Wasmtime::Module->validate('f00f')),
    F(),
    'validate bad',
  );

  is(
    [Wasm::Wasmtime::Module->validate('f00f')],
    array {
      item F();
      item match qr/./;
      end;
    },
    'validate bad, list context',
  );

  is(
    scalar(Wasm::Wasmtime::Module->validate(Wasm::Wasmtime::Store->new, 'f00f')),
    F(),
    'validate bad with store',
  );
};

subtest 'error' => sub {
  is(
    dies { Wasm::Wasmtime::Module->new('f00f') },
    match qr/error creating module/,
    'exception for bad wasm',
  );
};

is(
  Wasm::Wasmtime::Module->new(Wasm::Wasmtime::Engine->new, $wasm_binary),
  object {
    call ['isa', 'Wasm::Wasmtime::Module'] => T();
    if(Wasm::Wasmtime::FFI::_ver ne '0.27.0')
    {
      call type => object {
        call ['isa', 'Wasm::Wasmtime::ModuleType' ] => T();
      };
    }
  },
  'basic create',
);

is(
  Wasm::Wasmtime::Module->new(Wasm::Wasmtime::Engine->new, wat2wasm('(module)')),
  object {
    call ['isa', 'Wasm::Wasmtime::Module'] => T();
    call engine => object {
      call ['isa', 'Wasm::Wasmtime::Engine'] => T();
    };
    call to_string => "(module)\n";
    call serialize => match qr/./;
  },
  'explicit engine',
);

is(
  Wasm::Wasmtime::Module->new(wat2wasm('(module)')),
  object {
    call ['isa', 'Wasm::Wasmtime::Module'] => T();
    call engine => object {
      call ['isa', 'Wasm::Wasmtime::Engine'] => T();
    };
    call to_string => "(module)\n";
    call serialize => match qr/./;
  },
  'autocreate engine',
);

is(
  Wasm::Wasmtime::Module->deserialize(Wasm::Wasmtime::Module->new(wat2wasm('(module)'))->serialize),
  object {
    call ['isa', 'Wasm::Wasmtime::Module'] => T();
    call engine => object {
      call ['isa', 'Wasm::Wasmtime::Engine'] => T();
    };
    call to_string => "(module)\n";
  },
  'created module from serealized',
);

is(
  Wasm::Wasmtime::Module->deserialize(Wasm::Wasmtime::Engine->new, Wasm::Wasmtime::Module->new(wat2wasm('(module)'))->serialize),
  object {
    call ['isa', 'Wasm::Wasmtime::Module'] => T();
    call engine => object {
      call ['isa', 'Wasm::Wasmtime::Engine'] => T();
    };
    call to_string => "(module)\n";
  },
  'created module from store + serealized',
);

{
  my @warnings;
  local $SIG{__WARN__} = sub {
    push @warnings, @_;
  };

  is(
    Wasm::Wasmtime::Module->new(Wasm::Wasmtime::Store->new, wat2wasm('(module)')),
    object {
      call ['isa', 'Wasm::Wasmtime::Module'] => T();
      call engine => object {
        call ['isa', 'Wasm::Wasmtime::Engine'] => T();
      };
    },
    'explicit store',
  );

  note "warning:$_" for @warnings;
  is
    \@warnings,
    bag {
      item match qr/Passing a Wasm::Wasmtime::Store into the module constructor is deprecated, please pass a Wasm::Wasmtime::Engine object instead/;
      etc;
    },
    'deprecation warning',
  ;
}

is(
  Wasm::Wasmtime::Module->new(wat => '(module)'),
  object {
    call ['isa', 'Wasm::Wasmtime::Module'] => T();
    call engine => object {
      call ['isa', 'Wasm::Wasmtime::Engine'] => T();
    };
  },
  'wat key',
);

is(
  Wasm::Wasmtime::Module->new(wasm => wat2wasm('(module)')),
  object {
    call ['isa', 'Wasm::Wasmtime::Module'] => T();
    call engine => object {
      call ['isa', 'Wasm::Wasmtime::Engine'] => T();
    };
  },
  'wasm key',
);

is(
  Wasm::Wasmtime::Module->new(file => 'examples/wasmtime/gcd.wat'),
  object {
    call ['isa', 'Wasm::Wasmtime::Module'] => T();
    call engine => object {
      call ['isa', 'Wasm::Wasmtime::Engine'] => T();
    };
    call to_string => join("\n",
                        '(module',
                        '  (func (export "gcd") (param i32 i32) (result i32))',
                        ')',
                        '',
                      )
  },
  'file key',
);

is(
  Wasm::Wasmtime::Module->new(wat => q{
    (module
      (func (export "add") (param i32 i32) (result i32)
        local.get 0
        local.get 1
        i32.add)
      (func (export "sub") (param i64 i64) (result i64)
        local.get 0
        local.get 1
        i64.sub)
      (memory (export "frooble") 2 3)
    )
  }),
  object {
    call exports => object {
      call [ isa => 'Wasm::Wasmtime::Module::Exports' ] => T();
      call add => object {
        call [ isa => 'Wasm::Wasmtime::FuncType' ] => T();
      };
    };
    call_list sub { @{ shift->imports } } => [];
    call_list sub { @{ shift->exports } } => array {
      item object {
        call [ isa => 'Wasm::Wasmtime::ExportType' ] => T();
        call name => 'add';
        call type => object {
          call [ isa => 'Wasm::Wasmtime::FuncType' ] => T();
          call kind => 'functype';
          call_list params => array {
            item object {
              call [ isa => 'Wasm::Wasmtime::ValType' ] => T();
              call kind => 'i32';
            };
            item object {
              call [ isa => 'Wasm::Wasmtime::ValType' ] => T();
              call kind => 'i32';
            };
            end;
          };
          call_list results => array {
            item object {
              call [ isa => 'Wasm::Wasmtime::ValType' ] => T();
              call kind => 'i32';
            };
            end;
          };
        };
      };
      item object {
        call [ isa => 'Wasm::Wasmtime::ExportType' ] => T();
        call name => 'sub';
        call type => object {
          call kind => 'functype';
          call [ isa => 'Wasm::Wasmtime::FuncType' ] => T();
          call_list params => array {
            item object {
              call [ isa => 'Wasm::Wasmtime::ValType' ] => T();
              call kind => 'i64';
            };
            item object {
              call [ isa => 'Wasm::Wasmtime::ValType' ] => T();
              call kind => 'i64';
            };
            end;
          };
          call_list results => array {
            item object {
              call [ isa => 'Wasm::Wasmtime::ValType' ] => T();
              call kind => 'i64';
            };
            end;
          };
        };
      };
      item object {
        call [ isa => 'Wasm::Wasmtime::ExportType' ] => T();
        call name => 'frooble';
        call type => object {
          call [ isa => 'Wasm::Wasmtime::MemoryType' ] => T();
          call kind => 'memorytype';
        };
      };
      end;
    };
  },
  'exports',
);

wasm_module_ok '(module)';

done_testing;
