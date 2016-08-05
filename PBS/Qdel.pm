package PBS::Qdel; 

# pragma
use autodie; 
use warnings FATAL => 'all'; 

# cpan
use Moose::Role;  
use namespace::autoclean; 

# features
use experimental qw(signatures); 

# <roles> 
with qw(PBS::Prompt); 

# <methods> 
# kill job 
sub delete ( $self ) { 
    if ( $self->prompt('delete') ) { system 'qdel', $self->id  }
} 

1; 
