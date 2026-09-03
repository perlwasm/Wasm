package Wasm::Wasmtime::FFI;

use strict;
use warnings;
use 5.008004;
use FFI::C 0.05;
use FFI::C::Util ();
use FFI::Platypus 1.26;
use FFI::Platypus::Buffer ();
use FFI::CheckLib 0.26 qw( find_lib );
use Sub::Install;
use Devel::GlobalDestruction ();
use constant ();
use Carp ();
use base qw( Exporter );

# ABSTRACT: Private class for Wasm::Wasmtime
# VERSION

=head1 SYNOPSIS

 $ perldoc Wasm

=head1 DESCRIPTION

B<WARNING>: WebAssembly and Wasmtime are a moving target and the interface for these modules
is under active development.  Use with caution.

This is a private class used internally by L<Wasm::Wasmtime> classes.

As of this writing this module targets the modern C<wasmtime> C API (the
C<wasmtime_context_t> / C<wasmtime_store_t> based interface), and was developed
against Wasmtime 48.0.1.  The old C<wasm-c-api> object model (pre-1.0 Wasmtime)
is no longer supported.

The location of the Wasmtime shared library must currently be provided via the
C<WASM_WASMTIME_FFI> environment variable (the full path to F<libwasmtime.so>,
F<libwasmtime.dylib> or F<wasmtime.dll>).

=head1 SEE ALSO

=over 4

=item L<Wasm>

=item L<Wasm::Wasmtime>

=back

=cut

our @EXPORT = qw( $ffi $ffi_prefix _generate_vec_class _generate_destroy );

sub _lib
{
  return $ENV{WASM_WASMTIME_FFI} if defined $ENV{WASM_WASMTIME_FFI};

  # Sentinel symbols for a libwasmtime this distribution can actually use: the
  # modern store/context instance API plus the WAT, compiler and WASI features.
  # (This also rejects the feature-reduced "min" build shipped alongside the
  # standard one by Alien::wasmtime.)
  my @symbols = qw(
    wasmtime_wat2wasm
    wasmtime_module_new
    wasmtime_linker_define_wasi
    wasmtime_instance_export_nth
  );
  my $lib = find_lib lib => 'wasmtime', symbol => \@symbols;
  return $lib if $lib;

  # Fall back to Alien::wasmtime if it is installed (see the dynamic prereq in
  # dist.ini, which requires it when no system libwasmtime can be found).
  # Alien::wasmtime ships both a full library and a feature-reduced "min" build,
  # and ->dynamic_libs may list the "min" one first, so probe each candidate
  # ourselves and take the first that has every symbol we need.
  if(eval { require Alien::wasmtime; 1 })
  {
    foreach my $candidate (Alien::wasmtime->dynamic_libs)
    {
      my $ok = eval {
        my $probe = FFI::Platypus->new( api => 1, lib => $candidate );
        my $found = 1;
        foreach my $sym (@symbols)
        {
          $found = 0, last unless defined $probe->find_symbol($sym);
        }
        $found;
      };
      return $candidate if $ok;
    }
  }

  die "unable to locate a modern libwasmtime; set the WASM_WASMTIME_FFI "
    . "environment variable to the full path of the wasmtime shared library "
    . "(developed against wasmtime 48.0.1)\n";
}

our $ffi_prefix = 'wasm_';
our $ffi = FFI::Platypus->new( api => 1 );
FFI::C->ffi($ffi);
$ffi->lib(__PACKAGE__->_lib);
$ffi->mangler(sub {
  my $name = shift;
  return $name if $name =~ /^(wasm|wasmtime|wasi)_/;
  return $ffi_prefix . $name;
});

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

  $ffi->type('record(Wasm::Wasmtime::ByteVec)' => 'wasm_byte_vec_t');
  $ffi_prefix = 'wasm_byte_vec_';

  sub new
  {
    my $class = shift;
    if(@_ == 1)
    {
      my($data, $size) = FFI::Platypus::Buffer::scalar_to_buffer($_[0]);
      return $class->SUPER::new(
        size => $size,
        data => $data,
      );
    }
    else
    {
      return $class->SUPER::new(@_);
    }
  }

  sub get
  {
    my($self) = @_;
    FFI::Platypus::Buffer::buffer_to_scalar($self->data, $self->size);
  }

  $ffi->attach( delete => ['wasm_byte_vec_t*'] => 'void' );
}

sub _generic_vec_delete
{
  my($xsub, $self) = @_;
  $xsub->($self);
  # cannot use SUPER::DELETE because we aren't
  # in the right package.
  Wasm::Wasmtime::Vec::DESTROY($self);
}

sub _generate_vec_class
{
  my %opts = @_;
  my($class) = caller;
  my $type = $class;
  $type =~ s/^.*:://;
  my $v_type = "wasm_@{[ lc $type ]}_vec_t";
  my $vclass  = "Wasm::Wasmtime::${type}Vec";
  my $prefix = "wasm_@{[ lc $type ]}_vec";

  Sub::Install::install_sub({
    code => sub {
      my($self) = @_;
      my $size = $self->size;
      return () if $size == 0;
      my $ptrs = $ffi->cast('opaque', "opaque[$size]", $self->data);
      map { $class->new($_, $self) } @$ptrs;
    },
    into => $vclass,
    as   => 'to_list',
  });

  {
    no strict 'refs';
    @{join '::', $vclass, 'ISA'} = ('Wasm::Wasmtime::Vec');
  }
  $ffi_prefix = "${prefix}_";
  $ffi->type("record($vclass)" => $v_type);
  $ffi->attach( [ delete => join('::', $vclass, 'DESTROY') ] => ["$v_type*"] => \&_generic_vec_delete)
    if !defined($opts{delete}) || $opts{delete};

}

sub _wrapper_destroy
{
  my($xsub, $self) = @_;
  return if Devel::GlobalDestruction::in_global_destruction();
  if(defined $self->{ptr} && !defined $self->{owner})
  {
    $xsub->($self->{ptr});
    delete $self->{ptr};
  }
}

# _generate_destroy( $c_delete_function_name )
#
# Attaches a DESTROY method into the calling package that calls the named
# wasmtime/wasm "delete" function on $self->{ptr} (unless the object is owned
# by another object).  For backwards compatibility, when no name is given the
# mangled "${ffi_prefix}delete" symbol is used.
sub _generate_destroy
{
  my($fn) = @_;
  my $caller = caller;
  $fn = 'delete' unless defined $fn;
  $ffi->attach( [ $fn => join('::', $caller, 'DESTROY') ] => [ 'opaque' ] => 'void' => \&_wrapper_destroy);
}

{ package Wasm::Wasmtime::Error;

  $ffi_prefix = 'wasmtime_error_';
  $ffi->custom_type(
    wasmtime_error_t => {
      native_type => 'opaque',
      native_to_perl => sub {
        defined $_[0] ? __PACKAGE__->new($_[0]) : undef
      },
    },
  );

  Sub::Install::install_sub({
    code => sub {
      my($class, $ptr, $owner) = @_;
      bless {
        ptr   => $ptr,
        owner => $owner,
      }, $class;
    },
    into => __PACKAGE__,
    as   => 'new',
  });

  $ffi->attach( message => ['wasmtime_error_t','wasm_byte_vec_t*'] => sub {
    my($xsub, $self) = @_;
    my $message = Wasm::Wasmtime::ByteVec->new;
    $xsub->($self->{ptr}, $message);
    my $ret = $message->get;
    $message->delete;
    $ret;
  });

  # wasmtime_error_exit_status( error, int* ) -> bool
  $ffi->attach( [ exit_status => 'exit_status' ] => ['wasmtime_error_t','int*'] => 'bool' => sub {
    my($xsub, $self) = @_;
    my $status;
    $xsub->($self->{ptr}, \$status) ? $status : undef;
  });

  $ffi->attach( [ delete => "DESTROY" ] => ['wasmtime_error_t'] => sub {
    my($xsub, $self) = @_;
    if(defined $self->{ptr} && !defined $self->{owner})
    {
      $xsub->($self->{ptr});
    }
  });
}

#
# Modern Wasmtime "store handle" types.  These are small plain-old-data
# structures (a store id plus a private handle) that do not own anything and
# have no destructor.  Every operation on them requires a wasmtime_context_t.
#
# We model them with FFI::C structs of the exact C layout and always pass them
# by pointer.  The layouts below match the wasmtime C ABI from roughly v40
# onward (developed and tested against 48.0.1); older wasmtime releases used a
# different in-memory representation and are not supported.
#

{ package Wasm::Wasmtime::FuncData;
  # typedef struct wasmtime_func { uint64_t store_id; void *__private; }
  FFI::C->struct( wasmtime_func_t => [
    store_id  => 'uint64',
    _private  => 'opaque',
  ]);
}

{ package Wasm::Wasmtime::MemoryData;
  # typedef struct wasmtime_memory {
  #   struct { uint64_t store_id; uint32_t __private1; };  // padded to 16 bytes
  #   uint32_t __private2;                                  // at offset 16
  # };  // 24 bytes total
  FFI::C->struct( wasmtime_memory_t => [
    store_id => 'uint64',
    _p1      => 'uint32',
    _pad0    => 'uint32',
    _p2      => 'uint32',
    _pad1    => 'uint32',
  ]);
}

{ package Wasm::Wasmtime::TableData;
  # same layout as wasmtime_memory_t (24 bytes)
  FFI::C->struct( wasmtime_table_t => [
    store_id => 'uint64',
    _p1      => 'uint32',
    _pad0    => 'uint32',
    _p2      => 'uint32',
    _pad1    => 'uint32',
  ]);
}

{ package Wasm::Wasmtime::GlobalData;
  # typedef struct wasmtime_global { uint64_t store_id; uint32_t p1,p2,p3; }  // 24 bytes
  FFI::C->struct( wasmtime_global_t => [
    store_id => 'uint64',
    _p1      => 'uint32',
    _p2      => 'uint32',
    _p3      => 'uint32',
    _pad0    => 'uint32',
  ]);
}

{ package Wasm::Wasmtime::InstanceData;
  # typedef struct wasmtime_instance { uint64_t store_id; size_t __private; }
  FFI::C->struct( wasmtime_instance_t => [
    store_id => 'uint64',
    _private => 'size_t',
  ]);
}

our %EXTERN_KIND = (
  0 => 'func',
  1 => 'global',
  2 => 'table',
  3 => 'memory',
  4 => 'sharedmemory',
  5 => 'tag',
);
our %EXTERN_KIND_NUM = reverse %EXTERN_KIND;

{ package Wasm::Wasmtime::ExternUnion;
  FFI::C->union( wasmtime_extern_union_t => [
    func    => 'wasmtime_func_t',
    global  => 'wasmtime_global_t',
    table   => 'wasmtime_table_t',
    memory  => 'wasmtime_memory_t',
  ]);
}

{ package Wasm::Wasmtime::ExternData;
  # typedef struct wasmtime_extern { uint8_t kind; wasmtime_extern_union_t of; }
  FFI::C->struct( wasmtime_extern_t => [
    kind => 'uint8',
    of   => 'wasmtime_extern_union_t',
  ]);

  # Frees any owned resources held by an owned wasmtime_extern_t (as returned by
  # e.g. wasmtime_instance_export_get).  Safe/harmless for func/global/table/
  # memory kinds; the Perl-side struct memory is still freed by FFI::C.
  $ffi->attach( [ wasmtime_extern_delete => 'free' ] => ['wasmtime_extern_t'] => 'void' );
}

{ package Wasm::Wasmtime::ExternArray;
  FFI::C->array( wasmtime_extern_array_t => [ 'wasmtime_extern_t' ], { nullable => 1 } );
}

#
# wasmtime_val_t: a tagged union of WebAssembly values.  Numbering here is the
# wasmtime_valkind_t numbering, which differs from wasm_valkind_t (used by
# Wasm::Wasmtime::ValType) for the reference types.
#

our %VAL_KIND = (
  0 => 'i32',
  1 => 'i64',
  2 => 'f32',
  3 => 'f64',
  4 => 'v128',
  5 => 'funcref',
  6 => 'externref',
  7 => 'anyref',
);
our %VAL_KIND_NUM = reverse %VAL_KIND;

{ package Wasm::Wasmtime::ValUnion;
  FFI::C->union( wasmtime_valunion_t => [
    i32     => 'sint32',
    i64     => 'sint64',
    f32     => 'float',
    f64     => 'double',
    funcref => 'uint64[2]',
    v128    => 'uint8[16]',
    _pad    => 'uint8[24]',
  ]);
}

{ package Wasm::Wasmtime::Val;
  FFI::C->struct( wasmtime_val_t => [
    kind => 'uint8',
    of   => 'wasmtime_valunion_t',
  ]);

  sub to_perl
  {
    my $self = shift;
    my $kind = $VAL_KIND{$self->kind};
    return undef unless defined $kind;
    return $self->of->i32 if $kind eq 'i32';
    return $self->of->i64 if $kind eq 'i64';
    return $self->of->f32 if $kind eq 'f32';
    return $self->of->f64 if $kind eq 'f64';
    # reference / vector types not (yet) marshalled into Perl space
    return undef;
  }

  # Wasm::Wasmtime::Val->from_perl($kind_string, $value) -> Wasm::Wasmtime::Val
  sub from_perl
  {
    my($class, $kind, $value) = @_;
    my $num = $VAL_KIND_NUM{$kind};
    Carp::croak("cannot marshal WebAssembly value of type $kind") unless defined $num;
    my $self = $class->new;
    $self->kind($num);
    if($kind eq 'i32')    { $self->of->i32($value) }
    elsif($kind eq 'i64') { $self->of->i64($value) }
    elsif($kind eq 'f32') { $self->of->f32($value) }
    elsif($kind eq 'f64') { $self->of->f64($value) }
    else { Carp::croak("cannot marshal WebAssembly value of type $kind") }
    $self;
  }
}

{ package Wasm::Wasmtime::ValArray;
  FFI::C->array( wasmtime_val_array_t => [ 'wasmtime_val_t' ], { nullable => 1 } );

  sub to_perl
  {
    my $self = shift;
    map { $_->to_perl } @$self;
  }

  # from_perl(\@values, \@valtypes) where @valtypes are Wasm::Wasmtime::ValType
  sub from_perl
  {
    my($class, $vals, $types) = @_;
    return undef unless @$types;
    my $array = $class->new(scalar @$types);
    foreach my $i (0..$#$types)
    {
      my $kind = $types->[$i]->kind;
      my $num  = $VAL_KIND_NUM{$kind};
      Carp::croak("cannot marshal value of type $kind") unless defined $num;
      my $slot = $array->[$i];
      $slot->kind($num);
      if($kind eq 'i32') { $slot->of->i32($vals->[$i]) }
      elsif($kind eq 'i64') { $slot->of->i64($vals->[$i]) }
      elsif($kind eq 'f32') { $slot->of->f32($vals->[$i]) }
      elsif($kind eq 'f64') { $slot->of->f64($vals->[$i]) }
      else { Carp::croak("cannot marshal value of type $kind") }
    }
    $array;
  }
}

1;

=head1 SEE ALSO

=over 4

=item L<Wasm>

=item L<Wasm::Wasmtime>

=back

=cut
