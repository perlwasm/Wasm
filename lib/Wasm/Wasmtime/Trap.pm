package Wasm::Wasmtime::Trap;

use strict;
use warnings;
use 5.008004;
use FFI::Platypus::Buffer ();
use Wasm::Wasmtime::FFI;
use overload
  '""' => sub { shift->message . "\n" },
  bool => sub { 1 },
  fallback => 1;

# ABSTRACT: Wasmtime trap class
# VERSION

=head1 SYNOPSIS

# EXAMPLE: examples/synopsis/trap.pl

=head1 DESCRIPTION

B<WARNING>: WebAssembly and Wasmtime are a moving target and the interface for these modules
is under active development.  Use with caution.

This class represents a trap, usually something unexpected that happened in Wasm land.
This is usually converted into an exception in Perl land, but you can create your
own trap here.

=cut

$ffi_prefix = 'wasm_trap_';
$ffi->load_custom_type('::PtrObject' => 'wasm_trap_t' => __PACKAGE__);

=head1 CONSTRUCTORS

=head2 new

 my $trap = Wasm::Wasmtime::Trap->new($message);
 my $trap = Wasm::Wasmtime::Trap->new($store, $message);  # $store is ignored

Create a trap instance.  In the modern Wasmtime API traps are not associated with
a store, so the C<$store> argument (if given, for backwards compatibility) is
ignored.

=cut

$ffi->attach( [ wasmtime_trap_new => 'new' ] => [ 'opaque', 'size_t' ] => 'wasm_trap_t' => sub {
  my $xsub = shift;
  my $class = shift;
  if(@_ == 1 && defined $_[0] && !ref $_[0] && $_[0] =~ /^[0-9]+$/)
  {
    # wrap an existing wasm_trap_t pointer
    my $ptr = shift;
    return bless { ptr => $ptr }, $class;
  }
  # ignore a leading store argument (legacy calling convention)
  shift if @_ == 2;
  my $message = shift;
  $message = '' unless defined $message;
  $message =~ s/\0+$//;
  my($ptr, $len) = FFI::Platypus::Buffer::scalar_to_buffer($message);
  $xsub->($ptr, $len);
});

=head2 from_error

 my $trap = Wasm::Wasmtime::Trap->from_error($error);

Creates a trap from a L<Wasm::Wasmtime::Error>, carrying over its message and
(if present) its WASI exit status.

=cut

sub from_error
{
  my($class, $error) = @_;
  my $self = $class->new($error->message);
  $self->{exit_status} = $error->exit_status;
  $self;
}

=head1 METHODS

=head2 message

 my $message = $trap->message;

Returns the trap message as a string.

=cut

$ffi->attach( [ wasm_trap_message => 'message' ] => ['wasm_trap_t', 'wasm_byte_vec_t*'] => sub {
  my($xsub, $self) = @_;
  my $message = Wasm::Wasmtime::ByteVec->new;
  $xsub->($self, $message);
  my $ret = $message->get;
  $ret =~ s/\0$//;
  $message->delete;
  $ret;
});

=head2 exit_status

 my $status = $trap->exit_status;

If the trap was triggered by an C<exit> call this returns the exit status code,
otherwise C<undef>.  In the modern Wasmtime API exit status is carried by the
error rather than the trap, so this is populated by L<Wasm::Wasmtime> when it
converts an error into a trap and is C<undef> otherwise.

=cut

sub exit_status { shift->{exit_status} }

=head2 code

 my $code = $trap->code;

Returns the numeric instruction trap code, or C<undef> if this is not an
instruction trap.

=cut

$ffi->attach( [ wasmtime_trap_code => 'code' ] => ['wasm_trap_t','uint8*'] => 'bool' => sub {
  my($xsub, $self) = @_;
  my $code;
  $xsub->($self, \$code) ? $code : undef;
});

_generate_destroy('wasm_trap_delete');

1;

=head1 SEE ALSO

=over 4

=item L<Wasm>

=item L<Wasm::Wasmtime>

=back

=cut
