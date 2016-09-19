package PBS::Qdel; 

use autodie; 
use strict; 
use warnings FATAL => 'all'; 
use namespace::autoclean; 

use Moose::Role;  

use experimental qw( signatures ); 

sub qdel( $self, $job ) { 
    system 'qdel', $job;  
} 

1
