package Wasm::Memory;

use strict;
use warnings;
use 5.008004;
use Wasm::Wasmtime::Caller ();
use base qw( Exporter );

our @EXPORT_OK = qw( wasm_caller_memory );

# ABSTRACT: Interface to WebAssembly Memory
# VERSION

=head1 SYNOPSIS

Use WebAssembly memory from plain Perl:

# EXAMPLE: examples/synopsis/memory2.pl

Use WebAssembly memory from Perl in callback from WebAssembly:

# EXAMPLE: examples/synopsis/memory3.pl

=head1 DESCRIPTION

B<WARNING>: WebAssembly and Wasmtime are a moving target and the
interface for these modules is under active development.  Use with
caution.

This class represents a region of memory exported from a WebAssembly
module.  A L<Wasm::Memory> instance is automatically imported into
Perl space for each WebAssembly memory region with the same name.

=head1 FUNCTIONS

=head2 wasm_caller_memory

 my $memory = wasm_caller_memory;

Returns the memory region of the WebAssembly caller, if Perl has been
called by Wasm, otherwise it returns C<undef>.

This function can be exported by request via L<Exporter>.

=cut

sub wasm_caller_memory
{
  my $caller = Wasm::Wasmtime::Caller::wasmtime_caller();
  defined $caller
    ? do {
      my $wm = $caller->export_get('memory');
      defined $wm && $wm->is_memory
        ? __PACKAGE__->new($wm)
        : undef;
    } : undef;
}

sub new
{
  my($class, $memory) = @_;
  bless \$memory, $class;
}

=head1 METHODS

=head2 address

 my $pointer = $memory->address;

Returns an opaque pointer to the start of memory.

=head2 size

 my $size = $memory->size;

Returns the size of the memory in bytes.

=cut

sub address { ${shift()}->data      }
sub size    { ${shift()}->data_size }

=head2 limits

 my($current, $min, $max) = $memory->limits;

Returns the current memory limit, the minimum and maximum.  All sizes
are in pages.

=cut

sub limits
{
  my $self   = shift;
  my $memory = $$self;
  my $type   = $memory->type;
  ($memory->size, @{ $type->limits });
}

=head2 grow

 $memory->grow($count);

Grown the memory region by C<$count> pages.

=cut

sub grow
{
  my($self, $count) = @_;
  ${$self}->grow($count);
}

1;

=head1 SEE ALSO

=over 4

=item L<Wasm>

=back

=cut
