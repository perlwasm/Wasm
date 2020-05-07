package Wasm::Wasmtime::Module::Exports;

use strict;
use warnings;
use Carp ();

# ABSTRACT: Wasmtime module exports class
# VERSION

=head1 SYNOPSIS

# EXAMPLE: examples/synopsis/module_exports.pl

=head1 DESCRIPTION

B<WARNING>: WebAssembly and Wasmtime are a moving target and the interface for these modules
is under active development.  Use with caution.

TODO

=cut

sub new
{
  my($class, $module) = @_;

  $module->{exports} ||= do {
    my @exports = $module->exports;
    # TODO: lock with Hash::Util
    my %exports;
    foreach my $export (@exports)
    {
      $exports{$export->name} = $export->type;
    }
    \%exports;
  };

  bless \$module, $class;
}

sub can
{
  my($self, $name) = @_;
  my $module = $$self;
  $module->{exports}->{$name}
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
  my $export = $module->{exports}->{$name};
  Carp::croak("no export $name") unless $export;
  $export;
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
