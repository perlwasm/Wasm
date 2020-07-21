package Wasm::Trap;

use strict;
use warnings;
use 5.008004;

# ABSTRACT: Wasm Trap class
# VERSION

=head1 SYNOPSIS

=head1 DESCRIPTION

=head1 PROPERTIES

=head2 message

=head2 exit_status

=cut

sub _new
{
  my($class, $trap) = @_;
  bless \$trap, $class;
}

sub message
{
  my($self) = @_;
  my $trap = $$self;
  $trap->message;
}

sub exit_status
{
  my($self) = @_;
  my $trap = $$self;
  $trap->exit_status;
}

1;
