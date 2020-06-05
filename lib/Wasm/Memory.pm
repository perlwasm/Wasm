package Wasm::Memory;

use strict;
use warnings;

# ABSTRACT: Interface to WebAssembly Memory
# VERSION

=head1 SYNOPSIS

# EXAMPLE: examples/synopsis/memory2.pl

=head1 DESCRIPTION

This class represents a region of memory exported from a WebAssembly
module.  A L<Wasm::Memory> instance is automatically imported into
Perl space for each WebAssembly memory region with the same name.

=cut

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
