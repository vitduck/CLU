package PBS::Bootstrap; 

use 5.010; 

use autodie; 
use File::Path qw(rmtree); 
use Moose::Role;  
use namespace::autoclean; 

# roles
with qw(PBS::Qstat); 

has 'bootstrap' => ( 
    'is'      => 'ro', 
    'isa'     => 'Str', 
    'lazy'    => 1,   
    'default' => sub { 
        my ( $self ) = @_; 
        
        my $init_dir = $self->init; 
        
        if ( $self->owner eq $ENV{USER} ) { 
            return ( grep { -d and /bootstrap-\d+/ } glob "$init_dir/*" )[0]; 
        } else { 
            return ''; 
        }
    },    
); 

# remove bootstrap directory after job deletion
after delete => sub { 
    my ( $self ) = @_; 

    if ( $self->bootstrap ) { rmtree $self->bootstrap } 

    return; 
};  

1; 
