package PBS::Types; 

use strict; 
use warnings FATAL => 'all'; 

use MooseX::Types -declare => [ 'ID' ];   
use MooseX::Types::Moose 'Str'; 

subtype ID, as Str, where { /\d+(\.$ENV{HOSTNAME})?/ };  

1 
