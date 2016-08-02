package PBS::Qdel; 

# pragma
use autodie; 

# cpan
use Moose::Role;  
use namespace::autoclean; 

# features
use experimental qw(signatures); 

# <methods> 
# kill job 
sub delete ( $self ) { 
    system 'qdel', $self->id 
} 

1; 
