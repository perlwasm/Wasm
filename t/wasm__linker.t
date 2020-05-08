use Test2::V0 -no_srand => 1;
use Test2::Plugin::Wasm;
use Capture::Tiny qw( capture );
use lib 'corpus/wasm__linker/lib';
use YAML qw( Dump );

is( dies { require Module2 }, U(), 'require Module2');
is( dies { require Module3 }, match qr/module required by WebAssembly at.*Module3\.wat/, 'require Module3');

is
  [ capture { Module2::run() } ],
  ["Hello, world!\n", ''],
  'run it!',
;

note Dump(do { no warnings 'once'; \%Wasm::WASM });

done_testing;
