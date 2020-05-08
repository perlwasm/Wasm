# Wasm [![Build Status](https://travis-ci.org/perlwasm/Wasm.svg)](http://travis-ci.org/perlwasm/Wasm) ![windows](https://github.com/perlwasm/Wasm/workflows/windows/badge.svg) ![macos](https://github.com/perlwasm/Wasm/workflows/macos/badge.svg)

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

# GLOBALS

## %Wasm::WASM

This hash maps the Wasm module names to the files from which the Wasm was loaded.
It is roughly analogous to the `@INC` array in Perl.

# CAVEATS

As mentioned before as of this writing this dist is a work in progress.  I won't intentionally break
stuff if I don't have to, but practicality may demand it in some situations.

This interface is implemented using the bundled [Wasm::Wasmtime](https://metacpan.org/pod/Wasm::Wasmtime) family of modules, which depends
on the Wasmtime project.

The default way of handling out-of-bounds memory errors is to allocate large `PROT_NONE` pages at
startup.  While these pages do not consume many resources in practice (at least in the way that they
are used by Wasmtime), they can cause out-of-memory errors on Linux systems with virtual memory
limits (`ulimi -v` in the `bash` shell).  Similar techniques are common in other modern programming
languages, and this is more a limitation of the Linux kernel than anything else.  Setting the limits
on the virtual memory address size probably doesn't do what you think it is doing and you are probably
better off finding a way to place limits on process memory.

However, as a workaround for environments that choose to set a virtual memory address size limit anyway,
Wasmtime provides configurations to not allocate the large `PROT_NONE` pages at some performance
cost.  The testing plugin [Test2::Plugin::Wasm](https://metacpan.org/pod/Test2::Plugin::Wasm) tries to detect environments that have the virtual
memory address size limits and sets this configuration for you.  For production you can set the
environment variable `PERL_WASM_WASMTIME_MEMORY` to tune the appropriate memory settings exactly
as you want to (see the environment section of [Wasm::Wasmtime](https://metacpan.org/pod/Wasm::Wasmtime).

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
