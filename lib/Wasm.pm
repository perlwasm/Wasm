package Wasm;

use strict;
use warnings;
use 5.008001;
use Carp ();

# ABSTRACT: Write Perl extensions using Wasm
# VERSION

=head1 SYNOPSIS

# EXAMPLE: examples/synopsis/wasm.pl

=head1 DESCRIPTION

B<WARNING>: WebAssembly and Wasmtime are a moving target and the interface for these modules
is under active development.  Use with caution.

The C<Wasm> Perl dist provides tools for writing Perl bindings using WebAssembly (Wasm).

=head1 SEE ALSO

=over 4

=item L<Wasm::Wasmtime>

Low level interface to C<wasmtime>.

=back

=cut

sub import
{
  my $class = shift;
  my $caller = caller;

  return unless @_;

  if(defined $_[0] && $_[0] ne '-api')
  {
    Carp::croak("You MUST specify an api level as the first option");
  }

  my $api;
  my $wat;

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
      $wat = shift;
    }
    else
    {
      Carp::croak("Unknown Wasm option: $key");
    }
  }

  unless(defined $wat)
  {
    $wat = '(module)';
  }

  require Wasm::Wasmtime;
  my $config = Wasm::Wasmtime::Config->new;
  $config->wasm_multi_value(1);
  my $engine = Wasm::Wasmtime::Engine->new($config);
  my $store = Wasm::Wasmtime::Store->new($engine);

  my $module;
  if($wat)
  {
    $module = Wasm::Wasmtime::Module->new($store, wat => $wat)
  }
  else
  {
    die 'earm';
  }

  my $instance = Wasm::Wasmtime::Instance->new($module, []);

}

1;
