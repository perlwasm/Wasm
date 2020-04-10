use strict;
use warnings;
use Wasm::Wasmtime;

my $store = Wasm::Wasmtime::Store->new;

my $module = Wasm::Wasmtime::Module->new($store, wat => q{
  (module

    ;; callback we can make back into perl space
    (func $hello (import "" "hello"))
    (func (export "call_hello") (call $hello))

    ;; plain WebAssembly function that we can call from Perl
    (func (export "gcd") (param i32 i32) (result i32)
      (local i32)
      block  ;; label = @1
        block  ;; label = @2
          local.get 0
          br_if 0 (;@2;)
          local.get 1
          local.set 2
          br 1 (;@1;)
        end
        loop  ;; label = @2
          local.get 1
          local.get 0
          local.tee 2
          i32.rem_u
          local.set 0
          local.get 2
          local.set 1
          local.get 0
          br_if 0 (;@2;)
        end
      end
      local.get 2
    )
  )
});

my $hello = Wasm::Wasmtime::Func->new(
  $store,
  Wasm::Wasmtime::FuncType->new([],[]),
  sub { print "hello world!\n" },
);

my $instance = Wasm::Wasmtime::Instance->new( $module, [$hello] );

# call a WebAssembly function that calls back into Perl space
$instance->get_export('call_hello')->();

# call plain WebAssembly function
my $gcd = $instance->get_export('gcd');
print "gcd(6,27) = @{[ $gcd->(6,27) ]}\n";

