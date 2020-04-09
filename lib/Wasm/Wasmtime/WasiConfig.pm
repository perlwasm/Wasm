package Wasm::Wasmtime::WasiConfig;

use strict;
use warnings;
use Wasm::Wasmtime::FFI;

# ABSTRACT: Wasi Configuration
# VERSION

$ffi_prefix = 'wasi_config_';
$ffi->custom_type('wasi_config_t' => {
  native_type => 'opaque',
  perl_to_native => sub { shift->{ptr} },
  native_to_perl => sub { bless { ptr => shift }, __PACKAGE__ },
});

$ffi->attach( new             => []                                  => 'wasi_config_t' );
$ffi->attach( set_stdin_file  => ['wasi_config_t','string']          => 'void' );
$ffi->attach( set_stdout_file => ['wasi_config_t','string']          => 'void' );
$ffi->attach( set_stderr_file => ['wasi_config_t','string']          => 'void' );
$ffi->attach( preopen_dir     => ['wasi_config_t','string','string'] => 'void' );

foreach my $name (qw( argv env stdin stdout stderr ))
{
  $ffi->attach( "inherit_$name" => ['wasi_config_t'] );
}

$ffi->attach( set_argv => ['wasi_config_t', 'int', 'string[]'] => sub {
  my($xsub, $self, @argv) = @_;
  $xsub->($self, scalar(@argv), \@argv);
});

$ffi->attach( set_env => ['wasi_config_t','int','string[]','string[]'] => sub {
  my($xsub, $self, %env) = @_;
  my @names;
  my @values;
  foreach my $name (keys %env)
  {
    push @names,  $name;
    push @values, $env{$name};
  }
  $xsub->($self, scalar(@names), \@names, \@values);
});

$ffi->attach( [ 'delete' => 'DESTROY' ] => ['wasi_config_t'] => sub {
  my($xsub, $self) = @_;
  $xsub->($self) if $self->{ptr};
});

1;
