package Test2::Plugin::Wasm;

use strict;
use warnings;
use Test2::API qw( context );
use Test2::Mock;

# ABSTRACT: Test2 plugin for Wasm extensions
# VERSION

=head1 SYNOPSIS

 use Test2::Plugin::Wasm;

=head1 DESCRIPTION

This L<Test2> plugin is for testing L<Wasm> extensions.  Right now, it sets C<wasmtime> resource
limits to work on systems with a low virtual memory address limit.  It may do other thing that
make sense for all L<Wasm> extensions in the future.

=head1 SEE ALSO

=over 4

=item L<Wasm>

Write Perl extensions using Web Assembly.

=back

=cut

sub get_virtual_memory_limit
{
  my $ctx = context();
  if($^O eq 'linux')
  {
    require FFI::Platypus;
    require FFI::C::StructDef;
    my $ffi = FFI::Platypus->new( api => 1, lib => [undef] );
    my $rlimit;
    if($ffi->find_symbol('getrlimit64'))
    {
      $ctx->note("linux : found getrlimit64") if $ENV{TEST2_PLUGIN_WASM_DEBUG};
      $rlimit = FFI::C::StructDef->new(
        $ffi,
        name => 'rlimit',
        members => [
          rlim_cur => 'uint64',
          rlim_max => 'uint64',
        ],
      )->create;
      my $ret = $ffi->function( getrlimit64 => [ 'int', 'rlimit' ] => 'int' )->call(9,$rlimit);
      if($ret == -1)
      {
        $ctx->note("getrlimit64 failed: $!") if $ENV{TEST2_PLUGIN_WASM_DEBUG};
        undef $rlimit;
      }
    }
    elsif($ffi->find_symbol('getrlimit'))
    {
      $ctx->note("linux : found getrlimit") if $ENV{TEST2_PLUGIN_WASM_DEBUG};
      $rlimit = FFI::C::StructDef->new(
        $ffi,
        name => 'rlimit',
        members => [
          rlim_cur => 'uint32',
          rlim_max => 'uint32',
        ],
      )->create;
      my $ret = $ffi->function( getrlimit => [ 'int', 'rlimit' ] => 'int' )->call(9,$rlimit);
      if($ret == -1)
      {
        $ctx->note("getrlimit failed: $!") if $ENV{TEST2_PLUGIN_WASM_DEBUG};
        undef $rlimit;
      }
    }
    if(defined $rlimit)
    {
      my $max = $rlimit->rlim_max;
      $ctx->note("rlimit->rlim_max = $max") if $ENV{TEST2_PLUGIN_WASM_DEBUG};
      $ctx->release;
      return $max;
    }
  }
  $ctx->release;
  return undef;
}

our $config_mock;

sub import
{
  my $ctx = context();
  my $vm_limit = get_virtual_memory_limit();
  if(defined $vm_limit)
  {
    require Wasm::Wasmtime::Config;
    $config_mock = Test2::Mock->new(
      class => 'Wasm::Wasmtime::Config',
      around => [
        new => sub {
          my $orig = shift;
          my $self = shift->$orig(@_);
          $self->static_memory_maximum_size($vm_limit/4);
          $self->static_memory_guard_size(1024);
          $self->dynamic_memory_guard_size(1024);
          $self;
        },
      ],
    );
  }
  $ctx->release;
}

1;
