package PBS::Qdel; 

use autodie;  

use Moose::Role;  

use namespace::autoclean; 
use experimental qw( signatures ); 

sub qdel( $self, $job ) { 
    system 'qdel', $job;  
} 

1
