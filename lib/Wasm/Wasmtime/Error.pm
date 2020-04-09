package Wasm::Wasmtime::Error;

use strict;
use warnings;
use Wasm::Wasmtime::FFI;

# ABSTRACT: Wasmtime error class
# VERSION

$ffi_prefix = 'wasmtime_error_';
$ffi->custom_type(
  wasmtime_error_t => {
    native_type => 'opaque',
    native_to_perl => sub {
      defined $_[0] ? __PACKAGE__->new($_[0]) : undef
    },
  },
);

=head1 CONSTRUCTORS

=head2 new

=cut

sub new
{
  my($class, $ptr, $owner) = @_;
  bless {
    ptr   => $ptr,
    owner => $owner,
  }, $class;
}

if($ffi->find_symbol('wasmtime_error_message'))
{
  $ffi->attach( message => ['wasmtime_error_t','wasm_byte_vec_t*'] => sub {
    my($xsub, $self) = @_;
    my $message = Wasm::Wasmtime::ByteVec->new;
    $xsub->($self->{ptr}, $message);
    my $ret = $message->get;
    $message->delete;
    $ret;
  });

  $ffi->attach( [ delete => "DESTROY" ] => ['wasmtime_error_t'] => sub {
    my($xsub, $self) = @_;
    if(defined $self->{ptr} && !defined $self->{owner})
    {
      $xsub->($self->{ptr});
    }
  });
}

1;
