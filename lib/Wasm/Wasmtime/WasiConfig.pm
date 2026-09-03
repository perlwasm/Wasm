package Wasm::Wasmtime::WasiConfig;

use strict;
use warnings;
use 5.008004;
use Wasm::Wasmtime::FFI;
use Carp ();

# ABSTRACT: WASI Configuration
# VERSION

=head1 SYNOPSIS

# EXAMPLE: examples/synopsis/wasiconfig.pl

=head1 DESCRIPTION

B<WARNING>: WebAssembly and Wasmtime are a moving target and the interface for these modules
is under active development.  Use with caution.

This class represents the WebAssembly System Interface (WASI) configuration.

To apply a WASI configuration, pass it to C<< $store->set_wasi($config) >>
(which consumes it) and define the WASI imports on a linker with
C<< $linker->define_wasi >>.

=cut

$ffi_prefix = 'wasi_config_';
$ffi->load_custom_type('::PtrObject' => 'wasi_config_t' => __PACKAGE__);

=head1 CONSTRUCTOR

=head2 new

 my $config = Wasm::Wasmtime::WasiConfig->new;

Creates a new WASI config object.

=head1 METHODS

=head2 set_argv

 $config->set_argv(@argv);

=head2 inherit_argv

 $config->inherit_argv;

=head2 set_env

 $config->set_env(\%env);
 $config->set_env(%env);

=head2 inherit_env

=head2 set_stdin_file

 $config->set_stdin_file($path);

=head2 inherit_stdin

=head2 set_stdout_file

 $config->set_stdout_file($path);

=head2 inherit_stdout

=head2 set_stderr_file

 $config->set_stderr_file($path);

=head2 inherit_stderr

=head2 preopen_dir

 $config->preopen_dir($host_path, $guest_path);
 $config->preopen_dir($host_path, $guest_path, $fs_mutable);

Pre-open C<$host_path> from the host, visible to the guest as C<$guest_path>.
C<$fs_mutable> (default true) controls whether the guest may modify the
filesystem under that path.

=cut

sub _wrapper
{
  my $xsub = shift;
  my $self = shift;
  $xsub->($self, @_);
  $self;
}

$ffi->attach( new             => []                                       => 'wasi_config_t' );
$ffi->attach( set_stdin_file  => ['wasi_config_t','string']               => 'bool', \&_wrapper );
$ffi->attach( set_stdout_file => ['wasi_config_t','string']               => 'bool', \&_wrapper );
$ffi->attach( set_stderr_file => ['wasi_config_t','string']               => 'bool', \&_wrapper );
$ffi->attach( preopen_dir     => ['wasi_config_t','string','string','bool'] => 'bool' => sub {
  my $xsub = shift;
  my $self = shift;
  my($host, $guest, $fs_mutable) = @_;
  $fs_mutable = 1 unless defined $fs_mutable;
  $xsub->($self, $host, $guest, $fs_mutable);
  $self;
});

foreach my $name (qw( argv env stdin stdout stderr ))
{
  $ffi->attach( "inherit_$name" => ['wasi_config_t'] => 'void', \&_wrapper );
}

$ffi->attach( set_argv => ['wasi_config_t', 'size_t', 'string[]'] => 'bool' => sub {
  my($xsub, $self, @argv) = @_;
  $xsub->($self, scalar(@argv), \@argv);
  $self;
});

$ffi->attach( set_env => ['wasi_config_t','size_t','string[]','string[]'] => 'bool' => sub {
  my($xsub, $self, %env) = @_;
  my @names;
  my @values;
  foreach my $name (keys %env)
  {
    push @names,  $name;
    push @values, $env{$name};
  }
  $xsub->($self, scalar(@names), \@names, \@values);
  $self;
});

_generate_destroy('wasi_config_delete');

1;

=head1 SEE ALSO

=over 4

=item L<Wasm>

=item L<Wasm::Wasmtime>

=back

=cut
