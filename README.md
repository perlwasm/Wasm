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

**WARNING**: WebAssembly and Wasmtime are a moving target and the
interface for these modules is under active development.  Use with
caution.

The goal of this project is for Perl and WebAssembly to be able to call
each other transparently without having to know or care which module is
implemented in which language.  Perl subroutines and WebAssembly functions
can easily be imported and exported between Perl and WebAssembly
(see [Wasm::Func](https://metacpan.org/pod/Wasm::Func) for details).  WebAssembly global variables can be
imported into Perl using tied scalars (see [Wasm::Global](https://metacpan.org/pod/Wasm::Global) for details).
WebAssembly linear memory can be queried and manipulated by Perl
(see [Wasm::Memory](https://metacpan.org/pod/Wasm::Memory) for details).  WebAssembly can optionally be loaded
directly by Perl without writing any Perl wrappers at all (see [Wasm::Hook](https://metacpan.org/pod/Wasm::Hook)
for details).

The example above shows WebAssembly Text (WAT) inlined into the
Perl code for readability. In most cases you will want to compile your
WebAssembly from a higher level language (Rust, C, Go, etc.), and
install it alongside your Perl Module (.pm file) and use the `-self`
option below.  That is for `lib/Math.pm` you would install the Wasm
file into `lib/Math.wasm`, and use the `-self` option.

Modules using [Wasm](https://metacpan.org/pod/Wasm) can optionally use [Exporter](https://metacpan.org/pod/Exporter) to export WebAssembly
functions into other modules.  Using `-export 'ok'` functions can be
imported from a calling module on requests.  `-export 'all'` will
export all exported functions by default.

The current implementation uses [Wasm::Wasmtime](https://metacpan.org/pod/Wasm::Wasmtime), which is itself based
on the Rust project Wasmtime.  This module doesn't expose the
[Wasm::Wasmtime](https://metacpan.org/pod/Wasm::Wasmtime) interface, and implementation could be changed in the
future.

# OPTIONS

## -api

```perl
use Wasm -api => 0;
```

As of this writing, since the API is subject to change, this must be
provided and set to `0`.

## -exporter

```perl
use Wasm -api => 0, -exporter => 'all';
use Wasm -api => 0, -exporter => 'ok';
```

Configure the caller as an [Exporter](https://metacpan.org/pod/Exporter), with all the functions in the
WebAssembly either `@EXPORT` (`all`) or `@EXPORT_OK` (`ok`).

## -file

```perl
use Wasm -api => 0, -file => $file;
```

Path to a WebAssembly file in either WebAssembly Text (.wat) or
WebAssembly binary (.wasm) format.

## -global

```perl
use Wasm -api => 0, -global => [ $name, $type, $mutability, $init ];
```

Creates a global variable for the calling Pure-Perl module that can
be imported into WebAssembly.  If you use this option you cannot
specify the `-wat` or `-file` or `-self` options.  For a detailed
example see [Wasm::Global](https://metacpan.org/pod/Wasm::Global).

## -package

```perl
use Wasm -api => 0, -package => $package;
```

Install subroutines in to `$package` namespace instead of the calling
namespace.

## -self

```perl
use Wasm -api => 0, -self;
```

Look for a WebAssembly Text (.wat) or WebAssembly binary (.wasm) file
with the same base name as the Perl source this is called from.

For example if you are calling this from `lib/Foo/Bar.pm`, it will look
for `lib/Foo/Bar.wat` and `lib/Foo/Bar.wasm`.  If both exist, then it
will use the newer of the two.

## -wat

```perl
use Wasm -api => 0, -wat => $wat;
```

String containing WebAssembly Text (WAT).  Helpful for inline
WebAssembly inside your Perl source file.

# GLOBALS

## %Wasm::WASM

This hash maps the Wasm module names to the files from which the Wasm
was loaded. It is roughly analogous to the `%INC` hash in Perl.

# CAVEATS

As mentioned before as of this writing this dist is a work in progress.
I won't intentionally break stuff without a compelling reason, but
practicality may demand it in some situations.

This interface is implemented using the bundled [Wasm::Wasmtime](https://metacpan.org/pod/Wasm::Wasmtime) family
of modules, which depends on the Wasmtime project.

The default way of handling out-of-bounds memory errors is to allocate
large `PROT_NONE` pages at startup.  While these pages do not consume
many resources in practice (at least in the way that they are used by
Wasmtime), they can cause out-of-memory errors on Linux systems with
virtual memory limits (`ulimit -v` in the `bash` shell).  Similar
techniques are common in other modern programming languages, and this is
more a limitation of the Linux kernel than anything else.  Setting the
limits on the virtual memory address size probably doesn't do what you
think it is doing and you are probably better off finding a way to place
limits on process memory.

However, as a workaround for environments that choose to set a virtual
memory address size limit anyway, Wasmtime provides configurations to
not allocate the large `PROT_NONE` pages at some performance cost.  The
testing plugin [Test2::Plugin::Wasm](https://metacpan.org/pod/Test2::Plugin::Wasm) tries to detect environments that
have the virtual memory address size limits and sets this configuration
for you.  For production you can set the environment variable
`PERL_WASM_WASMTIME_MEMORY` to tune the appropriate memory settings
exactly as you want to (see the environment section of
[Wasm::Wasmtime](https://metacpan.org/pod/Wasm::Wasmtime).

# SEE ALSO

- [Wasm::Func](https://metacpan.org/pod/Wasm::Func)

    Interface to WebAssembly functions from Perl, and Perl subroutines
    from WebAssembly.

- [Wasm::Global](https://metacpan.org/pod/Wasm::Global)

    Interface to WebAssembly globals from Perl, and Perl globals from
    WebAssembly.

- [Wasm::Memory](https://metacpan.org/pod/Wasm::Memory)

    Interface to WebAssembly memory from Perl.

- [plasm](https://metacpan.org/pod/plasm)

    Perl WebAssembly command line tool.  Run WebAssembly programs from
    the command line, or dump their export/import interfaces.

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
