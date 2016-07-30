package PBS::Bootstrap; 

# pragma 
use autodie; 

# core 
use File::Path qw(rmtree); 

# cpan 
use Moose::Role;  
use namespace::autoclean; 

# features 
use experimental qw(signatures); 

# <roles> 
with qw(PBS::Qstat); 

# <attributes>
has 'bootstrap' => ( 
    'is'      => 'ro', 
    'isa'     => 'Str', 
    'lazy'    => 1,   
    'default' => sub ( $self ) { 
        my $init_dir = $self->init; 
        
        if ( $self->owner eq $ENV{USER} ) { 
            return ( grep { -d and /bootstrap-\d+/ } glob "$init_dir/*" )[0]; 
        } else { 
            return ''; 
        }
    },    
); 

# <methods> 
# remove bootstrap directory after job deletion
after delete => sub { 
    my ( $self ) = @_; 

    if ( $self->bootstrap ) { rmtree $self->bootstrap } 

    return; 
};  

1; 
