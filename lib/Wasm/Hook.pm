package Wasm::Hook;

use strict;
use warnings;
use autodie;
use 5.008001;
use Wasm 0.02;
use Ref::Util qw( is_ref );
use Path::Tiny qw( path );
use Scalar::Util qw( refaddr );

# ABSTRACT: Automatically load WebAssembly modules without a Perl wrapper
# VERSION

=head1 SYNOPSIS

 use Wasm::Hook;
 use Foo::Bar;  # will load Foo/Bar.wasm or Foo/Bar.wat if no Foo/Bar.pm is found
 no Wasm::Hook; # turns off automatic wasm / wat loading

=head1 DESCRIPTION

This module installs an C<@INC> hook that automatically loads WebAssembly (Wasm)
files so that they can be used like a Perl module, without:

The functions inside the WebAssembly module are exportable via the L<Exporter>
module.  C<@EXPORT_OK> is used, so you will need to explicitly export functions.

=over 4

=item

Having to write a boilerplate C<.pm> file that loads the WebAssembly

=item

The caller needing to even know or care that the module is implemented in something other than Perl.

=back

This module will only load a WebAssembly module if there is now Perl Module (C<.pm> file) with the appropriate name.

=head1 SEE ALSO

=over 4

=item L<Wasm>

=item L<Wasm::Wasmtime>

=back

=cut

sub _hook
{
  my(undef, $file) = @_;
  foreach my $inc (@INC)
  {
    next if ref $inc;
    my $pm = path($inc)->child($file);
    return () if -f $pm;
    my $basename = $pm->basename;
    $basename =~ s/\.pm$//;
    my($wa) = sort { $b->stat->mtime <=> $a->stat->mtime }
              grep { -f $_ }
              map { $pm->parent->child($basename . $_) }
              qw( .wasm .wat );
    next unless defined $wa;
    if(-f $wa)
    {
      my $package = $file;
      $package =~ s/\.pm$//;
      $package =~ s/\//::/g;
      my $perl = qq{package $package; use Wasm -api => 0, -exporter => 'ok', -file => "$wa"; 1;\n};
      my $fh;
      open $fh, '<', \$perl;
      return ($fh);
    }
  }
  return ();
}

sub import
{
  __PACKAGE__->unimport;
  push @INC, \&_hook;
}

sub unimport
{
  @INC = grep { !is_ref($_) || refaddr($_) != refaddr(\&_hook) } @INC;
}

1;
