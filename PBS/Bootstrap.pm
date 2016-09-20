package PBS::Bootstrap; 

use strict; 
use warnings FATAL => 'all'; 

use File::Path qw( rmtree ); 
use Term::ANSIColor; 
use Moose::Role;  
use MooseX::Types::Moose qw( HashRef ); 

use namespace::autoclean; 
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
            # dir glob 
            $bootstrap->{$job} = (
                grep { -d and /bootstrap-\d+/ } 
                glob "${\$self->get_init( $job )}/*" 
            )[0]; 
        }

        return $bootstrap
    },  

    handles   => { 
        has_bootstrap => 'defined', 
        get_bootstrap => 'get'
    } 
); 

sub delete_bootstrap ( $self, $job  ) { 
    rmtree $self->get_bootstrap( $job ) if $self->has_bootstrap( $job ) 
}

1 
