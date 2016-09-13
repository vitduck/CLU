package PBS::Bootstrap; 

use strict; 
use warnings FATAL => 'all'; 
use namespace::autoclean; 

use Term::ANSIColor; 
use File::Path qw( rmtree ); 

use Moose::Role;  
use MooseX::Types::Moose qw( HashRef ); 

use experimental qw( signatures ); 

has 'bootstrap', ( 
    is        => 'ro', 
    isa       => HashRef,  
    lazy      => 1, 
    traits    => [ 'Hash' ], 
    init_arg  => undef, 

    default   => sub ( $self ) { 
        my $bootstrap = { }; 

        for my $job ( $self->get_user_jobs ) { 
            # skip queued job 
            if ( $self->get_state( $job ) ne 'R' ) { next }   

            # dir glob 
            my $dir = ( 
                grep { -d and /bootstrap-\d+/ } 
                glob "${\$self->get_init( $job )}/*" 
            )[0]; 

            $bootstrap->{$job} = $dir if $dir; 
        }

        return $bootstrap
    },  

    handles   => { 
        has_bootstrap => 'count', 
        get_bootstrap => 'get'
    } 
); 

sub delete_bootstrap ( $self, $job  ) { 
    rmtree $self->get_bootstrap( $job ) if $self->has_bootstrap 
}

1 
