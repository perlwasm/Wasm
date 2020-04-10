use Test2::V0 -no_srand => 1;
use Wasm;

try_ok  { Wasm->import( -api => 0 );    }                                                   'works with -api => 0 ';
is(dies { Wasm->import( -api => 2 );    }, match qr/Currently only -api => 0 is supported/, 'dies with non 0 api level');
is(dies { Wasm->import( -foo => 'bar'); }, match qr/You MUST specify an api level as the first option/,
                                                                                            'bad key ');
is(dies { Wasm->import( -api => 0, -api => 0 ) },
                                           match qr/Specified -api more than once/,         'api more than once');
try_ok  { Wasm->import( -api => 0, -wat => '(module)' ) },                                  'empty module';

done_testing;


