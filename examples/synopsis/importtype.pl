use strict;
use warnings;
use Wasm::Wasmtime;

my $module = Wasm::Wasmtime::Module->new( wat => q{
  (module
    (func $hello (import "xx" "hello"))
  )
});

my $hello = $module->type->imports->[0];

print $hello->module, "\n";     # xx
print $hello->name, "\n";       # hello
print $hello->type->kind, "\n"; # functype
