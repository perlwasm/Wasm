use strict;
use warnings;
require Wasm;
Wasm->import(
  -api => 0,
  -wat => q{
    (module
      (func $hello (import "main" "hello"))
      (func (export "run") (call $hello))
    )
  },
);

sub hello
{
  print "Hello from Perl!\n";
}

run();
