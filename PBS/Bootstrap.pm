package PBS::Bootstrap; 

use strict; 
use warnings FATAL => 'all'; 
use feature 'signatures'; 
use namespace::autoclean; 

use File::Path 'rmtree'; 
use Term::ANSIColor; 
use Moose::Role;  
use MooseX::Types::Moose 'HashRef';  

no warnings 'experimental';  

has 'bootstrap', ( 
    is        => 'ro', 
    isa       => HashRef,  
    lazy      => 1, 
    traits    => [ 'Hash' ], 
    init_arg  => undef, 
    builder   => '_build_bootstrap', 
    handles   => { 
        has_bootstrap => 'defined', 
        get_bootstrap => 'get'
    } 
); 

sub _build_bootstrap ( $self ) { 
    my %bootstrap = (); 

    for my $job ( $self->get_user_jobs ) { 
        # dir glob 
        $bootstrap{$job} = (
            grep { -d and /bootstrap-\d+/ } 
            glob "${\$self->get_init( $job )}/*" 
        )[0]; 
    }

    return \%bootstrap
} 

sub delete_bootstrap ( $self, $job  ) { 
    rmtree $self->get_bootstrap( $job ) if $self->has_bootstrap( $job ) 
}

1 
