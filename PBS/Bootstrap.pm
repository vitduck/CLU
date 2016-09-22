package PBS::Bootstrap; 

use File::Path qw( rmtree );  

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
    builder   => '_build_bootstrap', 
    handles   => { 
        has_bootstrap => 'defined', 
        get_bootstrap => 'get'
    } 
); 

sub delete_bootstrap ( $self, $job  ) { 
    rmtree $self->get_bootstrap( $job ) if $self->has_bootstrap( $job ) 
}

1 
