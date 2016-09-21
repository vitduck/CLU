package PBS::Qdel; 

use autodie; 
use strict; 
use warnings FATAL => 'all'; 
use feature 'signatures';  
use namespace::autoclean; 

use Moose::Role;  

no warnings 'experimental'; 

sub qdel( $self, $job ) { 
    system 'qdel', $job;  
} 

1
