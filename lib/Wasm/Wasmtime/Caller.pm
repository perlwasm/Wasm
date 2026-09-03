package Wasm::Wasmtime::Caller;

use strict;
use warnings;
use 5.008004;
use FFI::Platypus::Buffer ();
use Wasm::Wasmtime::FFI;
use Wasm::Wasmtime::Extern;
use base qw( Exporter );

our @EXPORT = qw( wasmtime_caller );

$ffi_prefix = 'wasmtime_caller_';

# ABSTRACT: Wasmtime caller interface
# VERSION

=head1 SYNOPSIS

# EXAMPLE: examples/synopsis/caller.pl

=head1 DESCRIPTION

This class represents the caller's context when calling a Perl L<Wasm::Wasmtime::Func> from
WebAssembly.  The primary purpose of this structure is to provide access to the caller's
exported memory.

=head1 FUNCTIONS

=head2 wasmtime_caller

 my $caller = wasmtime_caller;
 my $caller = wasmtime_caller $index;

Returns the current caller context (an instance of L<Wasm::Wasmtime::Caller>), or
C<undef> if the current Perl code wasn't called from WebAssembly.  C<$index>
indicates how many WebAssembly call frames to go back.

This function is exported by default.

=cut

our @callers;

sub wasmtime_caller (;$)
{
  $callers[$_[0]||0]
}

=head1 METHODS

=head2 export_get

 my $extern = $caller->export_get($name);

Returns the L<Wasm::Wasmtime::Extern> for the named export C<$name>.  As of this
writing only L<Wasm::Wasmtime::Memory> exports are supported by Wasmtime here.

=cut

sub new
{
  my($class, $ptr, $store) = @_;
  bless {
    ptr   => $ptr,
    store => $store,
  }, $class;
}

=head2 store

 my $store = $caller->store;

Returns the L<Wasm::Wasmtime::Store> the caller belongs to.

=cut

sub store { shift->{store} }

$ffi->attach( export_get => ['opaque','opaque','size_t','wasmtime_extern_t'] => 'bool' => sub {
  my $xsub = shift;
  my $self = shift;
  return undef unless $self->{ptr};
  my $name = shift;
  $name = defined $name ? "$name" : "";
  my($nptr, $nlen) = FFI::Platypus::Buffer::scalar_to_buffer($name);
  my $extern = Wasm::Wasmtime::ExternData->new;
  return undef unless $xsub->($self->{ptr}, $nptr, $nlen, $extern);
  my $obj = Wasm::Wasmtime::Extern->from_extern($extern, $self->{store});
  $extern->free;
  $obj;
});

1;

=head1 SEE ALSO

=over 4

=item L<Wasm>

=item L<Wasm::Wasmtime>

=back

=cut
