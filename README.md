# Wasm [![Build Status](https://secure.travis-ci.org/perlwasm/Wasm.png)](http://travis-ci.org/perlwasm/Wasm) ![windows](https://github.com/perlwasm/Wasm/workflows/windows/badge.svg) ![macos](https://github.com/perlwasm/Wasm/workflows/macos/badge.svg)

Write Perl extensions using Wasm

# SYNOPSIS

lib/MathStuff.pm:

```perl
package MathStuff;

use strict;
use warnings;
use base qw( Exporter );
use Wasm
  -api => 0,
  -exporter => 'ok',
  -wat => q{
    (module
      (func (export "add") (param i32 i32) (result i32)
        local.get 0
        local.get 1
        i32.add)
      (func (export "subtract") (param i32 i32) (result i32)
        local.get 0
        local.get 1
        i32.sub)
      (memory (export "frooble") 2 3)
    )
  };

1;
```

mathstuff.pl:

```perl
use MathStuff qw( add subtract );

print add(1,2), "\n";      # prints 3
print subtract(3,2), "\n", # prints 1
```

# DESCRIPTION

**WARNING**: WebAssembly and Wasmtime are a moving target and the interface for these modules
is under active development.  Use with caution.

The `Wasm` Perl dist provides tools for writing Perl bindings using WebAssembly (Wasm).

# OPTIONS

## -api

```perl
use Wasm -api => 0;
```

As of this writing, since the API is subject to change, this must be provided and set to `0`.

## -exporter

```perl
use Wasm -api => 0, -exporter => 'all';
use Wasm -api => 0, -exporter => 'ok';
```

Configure the caller as an [Exporter](https://metacpan.org/pod/Exporter), with all the functions in the WebAssembly either `@EXPORT` (`all`)
or `@EXPORT_OK` (`ok`).

## -file

```perl
use Wasm -api => 0, -file => $file;
```

Path to a WebAssembly file in either WebAssembly Text (.wat) or WebAssembly binary (.wasm) format.

## -imports

```perl
use Wasm -api => 0, -imports => \@imports;
```

Use the given imports when creating the module instance.

## -package

```perl
use Wasm -api => 0, -package => $package;
```

Install subroutines in to `$package` namespace instead of the calling namespace.

## -self

```perl
use Wasm -api => 0, -self;
```

Look for a WebAssembly Text (.wat) or WebAssembly binary (.wasm) file with the same base name as
the Perl source this is called from.

For example if you are calling this from `lib/Foo/Bar.pm`, it will look for `lib/Foo/Bar.wat` and
`lib/Foo/Bar.wasm`.  If both exist, then it will use the newer of the two.

## -wat

```perl
use Wasm -api => 0, -wat => $wat;
```

String containing WebAssembly Text (WAT).  Helpful for inline WebAssembly inside your Perl source file.

# SEE ALSO

- [Wasm::Wasmtime](https://metacpan.org/pod/Wasm::Wasmtime)

    Low level interface to `wasmtime`.

- [Wasm::Hook](https://metacpan.org/pod/Wasm::Hook)

    Load WebAssembly modules as though they were Perl modules.

# AUTHOR

Graham Ollis <plicease@cpan.org>

# COPYRIGHT AND LICENSE

This software is copyright (c) 2020 by Graham Ollis.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.
