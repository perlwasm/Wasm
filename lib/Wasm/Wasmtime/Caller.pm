package Wasm::Wasmtime::Caller;

use strict;
use warnings;
use Wasm::Wasmtime::FFI;
use Wasm::Wasmtime::Extern;
use base qw( Exporter );

our @EXPORT = qw( wasmtime_caller );

$ffi_prefix = 'wasmtime_caller_';
$ffi->load_custom_type('::PtrObject' => 'wasmtime_caller_t' => __PACKAGE__);

# ABSTRACT: Wasmtime caller interface
# VERSION

=head1 SYNOPSIS

# EXAMPLE: examples/synopsis/caller.pl

=head1 DESCRIPTION

This class represents the caller's context when calling a Perl L<Wasm::Wasmtime::Func> from
WebAssembly.  The primary purpose of this structure is to provide access to the caller's
exported memory.  This allows functions which take pointers as arguments to easily read the
memory the pointers point into.

This is intended to be a pretty temporary mechanism for accessing the Caller's memory until
interface types has been fully standardized and implemented.

=head1 FUNCTIONS

=head2 wasmtime_caller

 my $caller = wasmtime_caller;
 my $caller = wasmtime_caller $index;

This returns the current caller context (an instance of L<Wasm::Wasmtime::Caller>).  If
the current Perl code wasn't called from WebAssembly, then it will return C<undef>.  If
C<$index> is given, then that indicates how many WebAssembly call frames to go back
before the current one.  (This is vaguely similar to how the Perl C<caller> function
works).

=cut

our @callers;

sub wasmtime_caller (;$)
{
  $callers[$_[0]||0]
}

=head1 METHODS

=head2 export_get

 my $extern = $caller->export_get($name);

Returns the L<Wasm::Wasmtime::Extern> for the named export C<$name>.  As of this writing,
only L<Wasm::Wasmtime::Memory> types are supported.

=cut

sub new
{
  my($class, $ptr) = @_;
  bless {
    ptr => $ptr,
  }, $class;
}

$ffi->attach( export_get => ['wasmtime_caller_t','wasm_byte_vec_t*'] => 'wasm_extern_t' => sub {
  my $xsub = shift;
  my $self = shift;
  return undef unless $self->{ptr};
  my $name = Wasm::Wasmtime::ByteVec->new($_[0]);
  $xsub->($self, $name);
});

1;

=head1 SEE ALSO

=over 4

=item L<Wasm>

=item L<Wasm::Wasmtime>

=back

=cut
