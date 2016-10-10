package PBS::Bookmark; 

use Moose::Role;  
use MooseX::Types::Moose qw( Undef Str Bool HashRef ); 
use File::Find; 
use namespace::autoclean; 
use experimental qw( signatures ); 

requires qw( _build_bookmark ); 

has 'follow_symbolic', ( 
    is        => 'ro', 
    isa       => Bool, 
    lazy      => 1, 
    init_arg  => undef,
    default   => 0, 
); 

has 'bookmark', ( 
    is        => 'ro', 
    isa       => HashRef[ Str | Undef ], 
    traits    => [ 'Hash' ], 
    lazy      => 1, 
    init_arg  => undef,
    builder   => '_build_bookmark', 
    handles   => { 
        has_bookmark => 'defined', 
        get_bookmark => 'get'
    }
); 

sub print_bookmark ( $self, $job ) { 
    if ( $self->has_bookmark( $job ) ) {  
        # trim the leading path 
        my $init     = $self->get_init( $job ); 
        my $bookmark = $self->get_bookmark( $job ) =~ s/$init\///r; 

        printf "%-9s=> %s\n", ucfirst( 'bookmark' ), $bookmark          
    }
} 

sub delete_bookmark ( $self, $job ) { 
    unlink join '/', $self->get_bookmark( $job), 'OUTCAR' if $self->has_bookmark( $job )
} 

1 
