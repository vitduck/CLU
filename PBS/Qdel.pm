package PBS::Qdel; 

use Moose::Role;  

use namespace::autoclean; 
use experimental 'signatures'; 

sub qdel ( $self, $job ) { 
    system 'qdel', $job;  
} 

1
