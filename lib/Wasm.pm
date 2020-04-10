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
 
 print add(1,2), "\n"; # 3
 print subtract(3,2), "\n", # 1

=head1 DESCRIPTION

B<WARNING>: WebAssembly and Wasmtime are a moving target and the interface for these modules
is under active development.  Use with caution.

The C<Wasm> Perl dist provides tools for writing Perl bindings using WebAssembly (Wasm).

=head1 OPTIONS

=head2 -api

 use Wasm -api => 0;

As of this writing, since the API is subject to change, this must be provided and set to C<0>.

=head2 -wat

 use Wasm -api => 0, -wat => $wat;

String containing WebAssembly Text (WAT).  Helpful for inline WebAssembly inside your Perl source file.

=head2 -file

 use Wasm -api => 0, -file => $file;

Path to a WebAssembly file in either WebAssembly Text (.wat) or WebAssembly binary (.wasm) format.

=head2 -self

 use Wasm -api => 0, -self;

Look for a WebAssembly Text (.wat) or WebAssembly binary (.wasm) file with the same base name as
the Perl source this is called from.

For example if you are calling this from C<lib/Foo/Bar.pm>, it will look for C<lib/Foo/Bar.wat> and
C<lib/Foo/Bar.wasm>.  If both exist, then it will use the newer of the two.

=head1 SEE ALSO

=over 4

=item L<Wasm::Wasmtime>

Low level interface to C<wasmtime>.

=back

=cut

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
  my @module;
  my $package = $caller;

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
      @module = (file => "$path");
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
        @module = (file => shift @maybe);
      }
    }
    else
    {
      Carp::croak("Unknown Wasm option: $key");
    }
  }

  @module = (wat => '(module)') unless @module;

  require Wasm::Wasmtime;
  my $config = Wasm::Wasmtime::Config->new;
  $config->wasm_multi_value(1);
  my $engine = Wasm::Wasmtime::Engine->new($config);
  my $store = Wasm::Wasmtime::Store->new($engine);
  my $module = Wasm::Wasmtime::Module->new($store, @module);
  my $instance = Wasm::Wasmtime::Instance->new($module, []);

  my @me = $module->exports;
  my @ie = $instance->exports;

  for my $i (0..$#ie)
  {
    my $exporttype = $me[$i];
    my $name = $me[$i]->name;
    my $externtype = $exporttype->type;
    my $extern = $ie[$i];
    if($externtype->kind eq 'func')
    {
      my $func = $extern->as_func;
      $func->attach($package, $name);
    }
  }
}

1;
