package PBS::Bookmark; 

use strict; 
use warnings FATAL => 'all'; 

use File::Find; 
use Term::ANSIColor; 
use Try::Tiny; 
use Moose::Role;  
use MooseX::Types::Moose qw( HashRef ); 

use namespace::autoclean; 
use experimental qw( signatures ); 

has 'bookmark', ( 
    is        => 'ro', 
    isa       => HashRef,  
    lazy      => 1, 
    traits    => [ 'Hash' ], 
    init_arg  => undef, 

    default   => sub ( $self ) { 
        my $bookmark = { }; 

        for my $job ( $self->get_user_jobs ) { 
            try { 
                my %mod_time = (); 
                find( 
                    { wanted => 
                        sub { $mod_time{$File::Find::name} = -M if /OUTCAR/ }, 
                        follow => $self->follow_symbolic 
                    }, $self->get_init( $job ) 
                ); 
                $bookmark->{$job} = ( 
                    sort { $mod_time{$a} <=> $mod_time{$b} } 
                    keys %mod_time 
                )[0] =~ s/\/OUTCAR//r; 
            }; 
        }

        return $bookmark; 
    }, 

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
        printf "%-9s=> %s\n", ucfirst('bookmark'), $bookmark          
    }
} 

sub remove_bookmark ( $self, $job ) { 
    unlink join '/', $self->get_bookmark( $job), 'OUTCAR' if  $self->has_bookmark( $job )
} 

1 
