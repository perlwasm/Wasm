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

  my $input_size   = do { use bytes; length($subject)+1 };
  my $input_offset = _allocate($input_size);
  strcpy( $memory->address + $input_offset, $subject );

  my $output_offset = _greet($input_offset);
  my $greeting      = FFI::Platypus->new->cast('opaque', 'string', $memory->address + $output_offset);
  my $output_size   = do { use bytes; length($greeting)+1 };

  _deallocate($input_offset,  $input_size);
  _deallocate($output_offset, $output_size);

  return $greeting;
}

1;
