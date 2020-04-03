package Wasm::Wasmtime;

use strict;
use warnings;
use 5.008001;
use Alien::wasmtime;
use Carp ();
use FFI::Platypus 1.00;
use base qw( Exporter );

our @EXPORT = qw( wat2wasm );

# ABSTRACT: Write Perl interface to wasmtime
# VERSION

=head1 SYNOPSIS

 use Wasm::Wasmtime;

 my $engine = Wasm::Wasmtime::Engine->new;
 my $wasm = wat2wasm($engine, "(module)");

=head2 DESCRIPTION

This module provides a low level interface for C<wasmtime>.

=cut

my $ffi = FFI::Platypus->new(
  api => 1,
  lib => [Alien::wasmtime->dynamic_libs],
);

$ffi->type('char'   => 'byte_t');
$ffi->type('float'  => 'float32_t');
$ffi->type('double' => 'float64_t');

{ package Wasm::Wasmtime::Config;
  $ffi->type('object(Wasm::Wasmtime::Config)' => 'wasm_config_t');
  $ffi->mangler(sub { "wasm_config_$_[0]" });

  $ffi->attach( new => [] => 'wasm_config_t' );
  #$ffi->attach( ['delete' => 'DESTROY'] => ['wasm_config_t'] ); # ??
}

{ package Wasm::Wasmtime::Engine;
  $ffi->type('object(Wasm::Wasmtime::Engine)' => 'wasm_engine_t');
  $ffi->mangler(sub { "wasm_engine_$_[0]" });

  $ffi->attach( ['new' => '_new'] => [] => 'wasm_engine_t' );
  $ffi->attach( ['new_with_config' => '_new_with_config'] => ['wasm_config_t'] => 'wasm_engine_t' );
  $ffi->attach( ['delete' => 'DESTROY'] => ['wasm_engine_t'] );

  sub new
  {
    my(undef, $config) = @_;
    $config ? _new_with_config($config) : _new();
  }
}

{ package Wasm::Wasmtime::Store;
  $ffi->type('object(Wasm::Wasmtime::Store)' => 'wasm_store_t');
  $ffi->mangler(sub { "wasm_store_$_[0]" });

  $ffi->attach( new => ['wasm_engine_t'] => 'wasm_store_t' => sub {
    my($xsub, undef, $engine) = @_;
    $xsub->($engine);
  });

  $ffi->attach( ['delete' => 'DESTROY'] => ['wasm_store_t'] );
}

# private class
{ package Wasm::Wasmtime::Vec;
  use FFI::Platypus::Record;
  record_layout_1(
    $ffi,
    size_t => 'size',
    opaque => 'data',
  );
}


{ package Wasm::Wasmtime::ByteVec;
  use base qw( Wasm::Wasmtime::Vec );
  use FFI::Platypus::Buffer ();

  $ffi->type('record(Wasm::Wasmtime::ByteVec)', 'wasm_byte_vec_t');
  $ffi->type('wasm_byte_vec_t', 'wasm_name_t');
  $ffi->type('wasm_name_t', 'wasm_message_t');
  $ffi->mangler(sub { "wasm_byte_vec$_[0]" });

  $ffi->attach( '_new'               => [ 'wasm_byte_vec_t*', 'size_t', 'opaque' ] => 'void' );
  $ffi->attach( '_new_uninitialized' => [ 'wasm_byte_vec_t*', 'size_t' ]           => 'void' );

  sub new
  {
    my($class, $arg) = @_;
    my $self = $class->SUPER::new;
    if(defined $arg)
    {
      my($ptr, $size) = FFI::Platypus::Buffer::scalar_to_buffer($arg);
      _new($self, $size, $ptr);
    }
    else
    {
      _new_uninitialized($self, 0);
    }
    $self;
  }

  sub _new_raw
  {
    my($class) = @_;
    $class->SUPER::new;
  }

  sub copy
  {
    my($self) = @_;
    my $copy = __PACKAGE__->SUPER::new;
    _new($copy, $self->size, $self->data);
    $copy;
  }

  sub to_string
  {
    my($self) = @_;
    return unless defined $self->data;
    my($buffer) = FFI::Platypus::Buffer::buffer_to_scalar($self->data, $self->size);
    $buffer;
  }

  $ffi->attach( ['_delete' => 'DESTROY'] => ['wasm_byte_vec_t*'] => sub {
    my($xsub, $self) = @_;
    $xsub->($self);
    $self->SUPER::DESTROY;
  });
}

{ package Wasm::Wasmtime::Module;
  $ffi->type('object(Wasm::Wasmtime::Module)' => 'wasm_module_t');
  $ffi->mangler(sub { "wasm_module_$_[0]" });

  $ffi->attach( new => ['wasm_store_t', 'wasm_byte_vec_t*'] => 'wasm_module_t' => sub {
    my($xsub, undef, $store, $wasm) = @_;
    $xsub->($store, $wasm);
  });

  $ffi->attach( validate => ['wasm_store_t', 'wasm_byte_vec_t*'] => 'bool' => sub {
    my($xsub, undef, $store, $wasm) = @_;
    $xsub->($store, $wasm);
  });

  $ffi->attach( ['delete' => 'DESTROY'] => ['wasm_module_t'] );
}

{ package Wasm::Wasmtime::Trap;
  $ffi->type('object(Wasm::Wasmtime::Trap)' => 'wasm_trap_t');
  $ffi->mangler(sub { "wasm_trap_$_[0]" });

  $ffi->attach( new => ['wasm_store_t', 'wasm_message_t*'] => 'wasm_trap_t' => sub {
    my($xsub, undef, $store, $messagep) = @_;
    my $message;
    if(ref $messagep)
    {
      $message = $messagep;
    }
    else
    {
      $messagep .= "\0" unless $messagep =~ /\0$/;
      $message = Wasm::Wasmtime::ByteVec->new($messagep);
    }
    $xsub->($store, $message);
  });

  sub _new_raw
  {
    my($class, $ptr) = @_;
    bless \$ptr, $class;
  }

  $ffi->attach( message => ['wasm_trap_t', 'wasm_message_t*'] => sub {
    my($xsub, $self) = @_;
    my $message = Wasm::Wasmtime::ByteVec->_new_raw;
    $xsub->($self, $message);
    $message = $message->to_string;
    $message =~ s/\0$//;
    $message;
  });

  $ffi->attach( ['delete' => 'DESTROY'] => ['wasm_trap_t'] );
}

{ package Wasm::Wasmtime::Instance;
  $ffi->type('object(Wasm::Wasmtime::Instance)' => 'wasm_instance_t');
  $ffi->mangler(sub { "wasm_instance_$_[0]" });

  $ffi->attach( new => [ 'wasm_store_t', 'wasm_module_t', 'opaque', 'opaque' ] => 'wasm_instance_t' => sub {
    my($xsub, undef, $store, $mod) = @_;
    # TODO: third argument is wasm_extern_t*[]
    my $trap;
    my $self = $xsub->($store, $mod, undef, \$trap);
    unless(defined $self)
    {
      # TODO: unit test for this, how do we get it to fail?
      $trap = Wasm::Wasmtime::Trap->_new_raw($trap);
      Carp::croak("error creating Wasm::Wasmtime::Instance " . $trap->message);
    }
    $self;
  });

  $ffi->attach( ['delete' => 'DESTROY'] => ['wasm_instance_t'] );
}

$ffi->mangler(sub { "wasmtime_$_[0]" });

=head1 FUNCTIONS

=head2 wat2wasm

 my $wasm = wat2wasm($engine, $wat);

Converts WebAssembly text format to Wasm.

=over

=item $engine

A L<Wasm::Wasmtime::Engine> instance.

=item $wat

Either a Perl string or a L<Wasm::Wasmtime::ByteVec> containing the WebAssembly text. 

=item $wasm

A L<Wasm::Wasmtime::ByteVec> containing the converted Wasm.

=back

=cut

$ffi->attach( wat2wasm => [ 'wasm_engine_t', 'wasm_byte_vec_t*', 'wasm_byte_vec_t*', 'wasm_byte_vec_t*' ] => 'bool' => sub {
  my($xsub, $engine, $watp) = @_;
  my $wat = ref $watp ? $watp : Wasm::Wasmtime::ByteVec->new($watp);
  my $ret = Wasm::Wasmtime::ByteVec->_new_raw;
  my $error_message = Wasm::Wasmtime::ByteVec->_new_raw;
  if($xsub->($engine, $wat, $ret, $error_message))
  {
    return $ret;
  }
  else
  {
    Carp::croak $error_message->to_string . "\nwat2wasm error";
  }
});

=head1 SEE ALSO

=over

=item L<Wasm>

=back

=cut

1;
