package PBS::Bootstrap; 

use strictures 2; 
use namespace::autoclean; 
use File::Path qw( rmtree ); 
use Term::ANSIColor; 
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
            next unless $self->get_state( $job ) eq 'R';  

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
        has_bootstrap => 'exists', 
        get_bootstrap => 'get'
    } 
); 

sub delete_job_bootstrap ( $self, $job  ) { 
    rmtree $self->get_bootstrap( $job ) if $self->has_bootstrap( $job );  
} 

1 
