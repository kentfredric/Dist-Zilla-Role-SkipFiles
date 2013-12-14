use strict;
use warnings;
use utf8;
package Dist::Zilla::Util::FileSkipper;

# ABSTRACT: Skip files from a list of files

use Moose;

=head1 DESCRIPTION

This module implements the guts of L<< C<Dist::Zilla::Role::SkipFiles>|Dist::Zilla::Role::SkipFiles >>

If you're writing a Plugin, that is probably what you want, unless you're doing something more advanced.

=head1 SYNOPSIS

    my $skipper = Dist::Zilla::Util::FileSkipper->new(
        skip_files => [ Array Of Eq Strings ]
    );
    # Basic Usage
    my @wanted_files = $skipper->filter_method( $self, 'found_files' );
    # Basic but precise usage
    for my $file ( $self->files ) {
        next if $skipper->should_skip_file( $file );
        ... 
    }
    # Advanced Usage
    my @wanted_files = $skipper->filter_finders( $zilla, @list_of_finders );
    my @wanted_files = $skipper->filter_finders_by_name( $zilla, @list_of_finder_names );


=cut

has skip_files => ( isa => ArrayRef =>, is => ro =>, lazy_build => 1 ); 

sub _build_skip_files { return [] };

sub match_skip_file_name {
    my ( $self, $skip_entry, $name ) = @_;
    return $skip_entry eq $name;
}

sub should_skip_file_name {
    my ( $self , $name ) = @_;
    for my $skip_entry ( @{ $self->skip_files  }) {
        return 1 if $self->match_skip_file_name( $skip_entry, $name );
    }
    return;
}

sub should_skip_file {
    my ( $self , $file ) = @_;
    return $self->should_skip_file_name( $file->name );
}

sub filter_skip {
    my ( $self, @files ) = @_;
    return grep { ! $self->should_skip_file($_) } @files;
}

sub filter_method {
    my ( $self, $object, $method ) = @_;
    if ( not $object->can($method) ) {
        require Carp;
        Carp::croak("$object can not call $method, can not filter its results");
    }
    return $self->filter_skip( $object->$method() );
}

sub filter_finders {
    my ( $self, $zilla, @finders ) = @_;
    my %out;
    for my $finder ( @finders ) {
        for my $found_file ( $finder->find_files ) {
            $out{ $found_file->name } = $found_file;
        }
    }
    return $self->filter_skip( values %out );
}

sub filter_finders_by_names {
    my ( $self, $zilla, @names ) = @_;
    my @finders;
    for my $name ( @names ) {
        my $plugin = $zilla->plugin_named( $name );
        if ( not $plugin ) {
            require Carp;
            Carp::confess("No plugin named $name found");
        }
        if ( not $plugin->does('Dist::Zilla::Role::FileFinder') ) {
            require Carp;
            Carp::confess("Plugin named $name is not a FileFinder");
        }
        push @finders, $plugin;
    }
    return $self->filter_finders( $zilla, @finders );
}

no Moose;
__PACKAGE__->meta->make_immutable;
1;

