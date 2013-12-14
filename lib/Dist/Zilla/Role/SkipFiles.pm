use strict;
use warnings;

package Dist::Zilla::Role::SkipFiles;

# ABSTRACT: Add a `skip_files` parameter on your Plugin

use Moose;

has skip_files         => ( isa => 'ArrayRef', is => ro =>, lazy_build => 1 );
has file_skipper_class => ( isa => 'Str',      is => ro =>, lazy_build => 1 );
has file_skipper       => ( isa => 'Object',   is => ro =>, lazy_build => 1, init_arg => undef );

sub _build_skip_files {
  return [];
}

sub _build_file_skipper_class {
  return 'Dist::Zilla::Util::FileSkipper';
}

sub _build_file_skipper {
  my ($self) = @_;
  require Module::Runtime;
  Module::Runtime::check_module_name( $self->file_skipper_class );
  Module::Runtime::require_module( $self->file_skipper_class );
  my $instance = $self->file_skipper_class->new( skip_files => $self->skip_files );
}
around dump_config => sub {
  my ( $orig, $self, @args ) = @_;
  my $config     = $self->$orig(@arg);
  my $own_config = {};
  $own_config->{skip_files}         = $self->skip_files;
  $own_config->{file_skipper_class} = $self->file_skipper_class;
  $config->{ q[] . __PACKAGE__ }    = $own_config;
  if ( $self->file_skipper->can('dump_config') ) {
    $config = $self->file_skipper->dump_config($config);
  }
  return $config;
};

__PACKAGE__->meta->make_immutable;
no Moose;

1;
