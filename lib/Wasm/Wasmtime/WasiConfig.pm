package Wasm::Wasmtime::WasiConfig;

use strict;
use warnings;
use Wasm::Wasmtime::FFI;

# ABSTRACT: Wasi Configuration
# VERSION

=head1 SYNOPSIS

# EXAMPLE: examples/synopsis/wasiconfig.pl

=head1 DESCRIPTION

B<WARNING>: WebAssembly and Wasmtime are a moving target and the interface for these modules
is under active development.  Use with caution.

This class represents the WebAssembly System Interface (WASI) configuration.  For WebAssembly WASI
is the equivalent to the part of libc that interfaces with the system.  As such it allows you to
configure if and how the WebAssembly program has access to program arguments, environment,
standard streams and file system directories.

=cut

$ffi_prefix = 'wasi_config_';
$ffi->custom_type('wasi_config_t' => {
  native_type => 'opaque',
  perl_to_native => sub { shift->{ptr} },
  native_to_perl => sub { bless { ptr => shift }, __PACKAGE__ },
});

=head1 CONSTRUCTOR

=head2 new

 my $config = Wasm::Wasmtime::WasiConfig->new;

Creates a new WASI config object.

=head1 METHODS

=head2 set_argv

 $config->set_argv(@argv);

Sets the program arguments.

=head2 inherit_argv

 $config->inherit_argv;

Configures WASI to use the host program's arguments.

=head2 set_env

 $config->set_env(\%env);

Sets the program environment variables.

=head2 inherit_env

 $config->inherit_env;

Configures WASI to use the host program's environment variables.

=head2 set_stdin_file

 $config->set_stdin_file($path);

Sets the program standard input to use the given file path.

=head2 inherit_stdin

 $config->inherit_stdin;

Configures WASI to use the host program's standard input.

=head2 set_stdout_file

 $config->set_stdout_file($path);

Sets the program standard output to use the given file path.

=head2 inherit_stdout

 $config->inherit_stdout;

Configures WASI to use the host program's standard output.

=head2 set_stderr_file

 $config->set_stderr_file($path);

Sets the program standard error to use the given file path.

=head2 inherit_stderr

 $config->inherit_stderr;

Configures WASI to use the host program's standard error.

=head2 preopen_dir

 $config->preopen_dir($host_path, $guest_path);

Pre-open the given directory from the host's C<$host_path> to the guest's C<$guest_path>.

=cut

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
