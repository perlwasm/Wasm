package Wasm;

use strict;
use warnings;
use 5.008001;
use Carp ();

# ABSTRACT: Write Perl extensions using Wasm
# VERSION

=head1 SYNOPSIS

lib/MathStuff.pm:

# EXAMPLE: examples/synopsis/wasm.pl

mathstuff.pl:

 use MathStuff qw( add subtract );
 
 print add(1,2), "\n";      # prints 3
 print subtract(3,2), "\n", # prints 1

=head1 DESCRIPTION

B<WARNING>: WebAssembly and Wasmtime are a moving target and the interface for these modules
is under active development.  Use with caution.

The C<Wasm> Perl dist provides tools for writing Perl bindings using WebAssembly (Wasm).

=head1 OPTIONS

=head2 -api

 use Wasm -api => 0;

As of this writing, since the API is subject to change, this must be provided and set to C<0>.

=head2 -exporter

 use Wasm -api => 0, -exporter => 'all';
 use Wasm -api => 0, -exporter => 'ok';

Configure the caller as an L<Exporter>, with all the functions in the WebAssembly either C<@EXPORT> (C<all>)
or C<@EXPORT_OK> (C<ok>).

=head2 -file

 use Wasm -api => 0, -file => $file;

Path to a WebAssembly file in either WebAssembly Text (.wat) or WebAssembly binary (.wasm) format.

=head2 -package

 use Wasm -api => 0, -package => $package;

Install subroutines in to C<$package> namespace instead of the calling namespace.

=head2 -self

 use Wasm -api => 0, -self;

Look for a WebAssembly Text (.wat) or WebAssembly binary (.wasm) file with the same base name as
the Perl source this is called from.

For example if you are calling this from C<lib/Foo/Bar.pm>, it will look for C<lib/Foo/Bar.wat> and
C<lib/Foo/Bar.wasm>.  If both exist, then it will use the newer of the two.

=head2 -wat

 use Wasm -api => 0, -wat => $wat;

String containing WebAssembly Text (WAT).  Helpful for inline WebAssembly inside your Perl source file.

=head1 CAVEATS

As mentioned before as of this writing this dist is a work in progress.  I won't intentionally break
stuff if I don't have to, but practicality may demand it in some situations.

This interface is implemented using the bundled L<Wasm::Wasmtime> family of modules, which depends
on the Wasmtime project.

The default way of handling out-of-bounds memory errors is to allocate large C<PROT_NONE> pages at
startup.  While these pages do not consume many resources in practice (at least in the way that they
are used by Wasmtime), they can cause out-of-memory errors on Linux systems with virtual memory
limits (C<ulimi -v> in the C<bash> shell).  Similar techniques are common in other modern programming
languages, and this is more a limitation of the Linux kernel than anything else.  Setting the limits
on the virtual memory address size probably doesn't do what you think it is doing and you are probably
better off finding a way to place limits on process memory.

However, as a workaround for environments that choose to set a virtual memory address size limit anyway,
Wasmtime provides configurations to not allocate the large C<PROT_NONE> pages at some performance
cost.  The testing plugin L<Test2::Plugin::Wasm> tries to detect environments that have the virtual
memory address size limits and sets this configuration for you.  For production you can set the
environment variable C<PERL_WASM_WASMTIME_MEMORY> to tune the appropriate memory settings exactly
as you want to (see the environment section of L<Wasm::Wasmtime>.

=head1 SEE ALSO

=over 4

=item L<Wasm::Wasmtime>

Low level interface to C<wasmtime>.

=item L<Wasm::Hook>

Load WebAssembly modules as though they were Perl modules.

=back

=cut

my $linker;

sub import
{
  my $class = shift;
  my($caller, $fn) = caller;

  return unless @_;

  if(defined $_[0] && $_[0] ne '-api')
  {
    Carp::croak("You MUST specify an api level as the first option");
  }

  my $api;
  my $exporter;
  my @module;
  my($package, $file) = $caller;  # note: file used only for diagnostics

  while(@_)
  {
    my $key = shift;
    if($key eq '-api')
    {
      if(defined $api)
      {
        Carp::croak("Specified -api more than once");
      }
      $api = shift;
      unless(defined $api && $api == 0)
      {
        Carp::croak("Currently only -api => 0 is supported");
      }
    }
    elsif($key eq '-wat')
    {
      my $wat = shift;
      Carp::croak("-wat undefined") unless defined $wat;
      @module = (wat => $wat);
    }
    elsif($key eq '-file')
    {
      my $path = shift;
      unless(defined $path && -f $path)
      {
        $path = 'undef' unless defined $path;
        Carp::croak("no such file $path");
      }
      $file = "$path";
      @module = (file => $file);
    }
    elsif($key eq '-self')
    {
      require Path::Tiny;
      my $perl_path = Path::Tiny->new($fn);
      my $basename = $perl_path->basename;
      $basename =~ s/\.(pl|pm)$//;
      my @maybe = sort { $b->stat->mtime <=> $a->stat->mtime } grep { -f $_ } (
        $perl_path->parent->child($basename . ".wasm"),
        $perl_path->parent->child($basename . ".wat"),
      );
      if(@maybe == 0)
      {
        Carp::croak("unable to find .wasm or .wat file relative to Perl source");
      }
      else
      {
        $file = shift @maybe;
        @module = (file => $file);
      }
    }
    elsif($key eq '-exporter')
    {
      $exporter = shift;
    }
    elsif($key eq '-package')
    {
      $package = shift;
    }
    elsif($key eq '-imports')
    {
      Carp::croak("-imports was removed in Wasm.pm 0.08");
    }
    else
    {
      Carp::croak("Unknown Wasm option: $key");
    }
  }

  @module = (wat => '(module)') unless @module;

  require Wasm::Wasmtime;
  $linker ||= do {
    my $linker = Wasm::Wasmtime::Linker->new(
      Wasm::Wasmtime::Store->new(
        Wasm::Wasmtime::Engine->new(
          Wasm::Wasmtime::Config
            ->new
            ->wasm_multi_value(1),
        ),
      ),
    );

    $linker->allow_shadowing(0);

    $linker->define_wasi(
      Wasm::Wasmtime::WasiInstance->new(
        $linker->store,
        'wasi_snapshot_preview1',
        Wasm::Wasmtime::WasiConfig
          ->new
          ->set_argv(@ARGV)
          ->inherit_env
          ->inherit_stdin
          ->inherit_stdout
          ->inherit_stderr
          #->preopen_dir ?
      )
    );

    $linker;
  };
  my $module = Wasm::Wasmtime::Module->new($linker->store, @module);

  foreach my $import (@{ $module->imports })
  {
    my $module = $import->module;
    next if $module eq 'wasi_snapshot_preview1';
    my $pm = "$module.pm";
    $pm =~ s{::}{/}g;
    eval { require $pm };
    if(my $error = $@)
    {
      $error =~ s/ at (.*?)$//;
      $error .= " module required by WebAssembly at $file";
      Carp::croak("$error");
    }
  }

  my $instance = $linker->instantiate($module);
  $linker->define_instance($package, $instance);

  my @me = @{ $module->exports   };
  my @ie = @{ $instance->exports };

  my @function_names;

  for my $i (0..$#ie)
  {
    my $exporttype = $me[$i];
    my $name = $me[$i]->name;
    my $externtype = $exporttype->type;
    my $extern = $ie[$i];
    if($externtype->kind eq 'functype')
    {
      my $func = $extern;
      $func->attach($package, $name);
      push @function_names, $name;
    }
  }

  if($exporter)
  {
    require Exporter;
    no strict 'refs';
    push @{ "${package}::ISA"       }, 'Exporter';
    if($exporter eq 'all')
    {
      push @{ "${package}::EXPORT" }, @function_names;
    }
    else
    {
      push @{ "${package}::EXPORT_OK" }, @function_names;
    }
  }
}

1;
