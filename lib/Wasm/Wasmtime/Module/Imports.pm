package Wasm::Wasmtime::Module::Imports;

use strict;
use warnings;
use 5.008004;
use Carp ();
use Hash::Util ();
use overload
  '%{}' => sub {
    my $self   = shift;
    my $module = $$self;
    $module->{imports};
  },
  '@{}' => sub {
    my $self = shift;
    my $module = $$self;
    my @imports = $module->_imports;
    Internals::SvREADONLY @imports, 1;
    Internals::SvREADONLY $imports[$_], 1 for 0..$#imports;
    \@imports;
  },
  bool => sub { 1 },
  fallback => 1;

# ABSTRACT: Wasmtime module imports class
# VERSION

=head1 SYNOPSIS

# EXAMPLE: examples/synopsis/module_imports.pl

=head1 DESCRIPTION

B<WARNING>: WebAssembly and Wasmtime are a moving target and the interface for these modules
is under active development.  Use with caution.

This class represents the imports from a module.  It can be used in a number of different ways.

=over 4

=item autoload methods

 my $foo = $module->imports->foo;

Calling the name of an export as a method returns the L<Wasm::Wasmtime::ExternType> for the
export.

=item As a hash reference

 my $foo = $module->imports->{foo};

Using the Imports class as a hash reference allows you to get imports that might clash with
common Perl methods like C<new>, C<can>, C<DESTROY>, etc.  The L<Wasm::Wasmtime::ExternType>
will be returned.

=item An array reference

 my $foo = $module->imports->[0];

This will give you the list of imports in the order that they are defined in your WebAssembly.
The object returned is a L<Wasm::Wasmtime::ExportType>, which is essentially a name and a
L<Wasm::Wasmtime::ExternType>.

=back

=cut

sub new
{
  my($class, $module) = @_;

  $module->{imports} ||= do {
    my @imports = $module->_imports;
    my %imports;
    foreach my $export (@imports)
    {
      $imports{$export->name} = $export->type;
    }
    Hash::Util::lock_hash(%imports);
    \%imports;
  };

  bless \$module, $class;
}

sub can
{
  my($self, $name) = @_;
  my $module = $$self;
  exists $module->{imports}->{$name}
    ? sub { $self->$name }
    : $self->SUPER::can($name);
}

sub AUTOLOAD
{
  our $AUTOLOAD;
  my $self = shift;

  my $name = $AUTOLOAD;
  $name=~ s/^.*:://;

  my $module = $$self;
  Carp::croak("no export $name") unless exists $module->{imports}->{$name};
  $module->{imports}->{$name};
}

sub DESTROY
{
  # needed because of AUTOLOAD
}

=head1 SEE ALSO

=over 4

=item L<Wasm>

=item L<Wasm::Wasmtime>

=back

=cut

1;
