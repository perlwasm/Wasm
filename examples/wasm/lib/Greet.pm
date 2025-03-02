package Greet;

use strict;
use warnings;
use FFI::Platypus;
use FFI::Platypus::Memory qw( strcpy );
use base qw( Exporter );
use Wasm
  -api => 0,
  -self
;

our @EXPORT = qw( greet );

sub greet
{
  my($subject) = @_;

  my $input_offset = _allocate(length($subject) + 1);
  strcpy( $memory->address + $input_offset, $subject );

  my $output_offset = _greet($input_offset);
  my $greeting      = FFI::Platypus->new->cast('opaque', 'string', $memory->address + $output_offset);

  _deallocate($input_offset);
  _deallocate($output_offset);

  return $greeting;
}

1;
