package Wasm::Wasmtime::Config;

use strict;
use warnings;
use Wasm::Wasmtime::FFI;
use Wasm::Wasmtime::Error;

# ABSTRACT: Global configuration for Wasm::Wasmtime::Engine
# VERSION

$ffi_prefix = 'wasm_config_';
$ffi->type('opaque' => 'wasm_config_t');

$ffi->attach( new => [] => 'wasm_config_t' => sub {
  my($xsub, $class) = @_;
  bless {
    ptr => $xsub->(),
  }, $class;
});


$ffi->attach( [ 'delete' => 'DESTROY' ] => ['wasm_config_t'] => sub {
  my($xsub, $self) = @_;
  $xsub->($self->{ptr}) if $self->{ptr};
});

foreach my $prop (qw( debug_info wasm_threads wasm_reference_types
                      wasm_simd wasm_bulk_memory wasm_multi_value
                      cranelift_debug_verifier ))
{
  $ffi->attach( [ "wasmtime_config_${prop}_set" => $prop ] => [ 'opaque', 'bool' ] => sub {
    my($xsub, $self, $value) = @_;
    $xsub->($self->{ptr}, $value);
    $self;
  });
}

my %strategy = (
  auto      => 0,
  cranelift => 1,
  lightbeam => 2,
);

if($ffi->find_symbol('wasmtime_error_message'))
{
  $ffi->attach( [ 'wasmtime_config_strategy_set' => 'strategy' ] => [ 'wasm_config_t', 'uint8' ] => 'wasmtime_error_t' => sub {
    my($xsub, $self, $value) = @_;
    if(defined $strategy{$value})
    {
      if(my $error = $xsub->($self->{ptr}, $strategy{$value}))
      {
        $error = Wasm::Wasmtime::Error->new($error)->message;
        Carp::croak($error);
      }
    }
    else
    {
      Carp::croak("unknown strategy: $value");
    }
    $self;
  });
}
else
{
  $ffi->attach( [ 'wasmtime_config_strategy_set' => 'strategy' ] => [ 'wasm_config_t', 'uint8' ] => 'bool' => sub {
    my($xsub, $self, $value) = @_;
    if(defined $strategy{$value})
    {
      unless(my $ret = $xsub->($self->{ptr}, $strategy{$value}))
      {
        Carp::croak("error setting strategy $value");
      }
    }
    else
    {
      Carp::croak("unknown strategy: $value");
    }
    $self;
  });
}

my %cranelift_opt_level = (
  none => 0,
  speed => 1,
  speed_and_size => 2,
);

$ffi->attach( ['wasmtime_config_cranelift_opt_level_set' => 'cranelift_opt_level' ] => ['wasm_config_t', 'uint8' ] => sub {
  my($xsub, $self, $value) = @_;
  if(defined $cranelift_opt_level{$value})
  {
    $xsub->($self->{ptr}, $cranelift_opt_level{$value});
  }
  else
  {
    Carp::croak("unknown cranelift_opt_level: $value");
  }
  $self;
});

my %profiler = (
  none    => 0,
  jitdump => 1,
);

if($ffi->find_symbol('wasmtime_error_message'))
{
  $ffi->attach( ['wasmtime_config_profiler_set' => 'profiler' ] => ['wasm_config_t', 'uint8'] => 'wasmtime_error_t' => sub {
    my($xsub, $self, $value) = @_;
    if(defined $profiler{$value})
    {
      if(my $error = $xsub->($self->{ptr}, $profiler{$value}))
      {
        $error = Wasm::Wasmtime::Error->new($error)->message;
        Carp::croak($error);
      }
    }
    else
    {
      Carp::croak("unknown profiler: $value");
    }
    $self;
  });
}
else
{
  $ffi->attach( ['wasmtime_config_profiler_set' => 'profiler' ] => ['wasm_config_t', 'uint8'] => 'bool' => sub {
    my($xsub, $self, $value) = @_;
    if(defined $profiler{$value})
    {
      unless(my $ret = $xsub->($self->{ptr}, $profiler{$value}))
      {
        Carp::croak("error setting profiler $value");
      }
    }
    else
    {
      Carp::croak("unknown profiler: $value");
    }
    $self;
  });
}

1;
