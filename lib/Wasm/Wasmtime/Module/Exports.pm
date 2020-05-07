package Wasm::Wasmtime::Module::Exports;

use strict;
use warnings;
use Carp ();
use Hash::Util ();
use overload
  '%{}' => sub {
    my $self   = shift;
    my $module = $$self;
    $module->{exports};
  },
  '@{}' => sub {
    my $self = shift;
    my $module = $$self;
    my @exports = $module->exports;
    Internals::SvREADONLY @exports, 1;
    Internals::SvREADONLY $exports[$_], 1 for 0..$#exports;
    \@exports;
  },
  bool => sub { 1 },
  fallback => 1;

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
    Hash::Util::lock_hash(%exports);
    \%exports;
  };

  bless \$module, $class;
}

sub can
{
  my($self, $name) = @_;
  my $module = $$self;
  exists $module->{exports}->{$name}
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
  Carp::croak("no export $name") unless exists $module->{exports}->{$name};
  $module->{exports}->{$name};
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
