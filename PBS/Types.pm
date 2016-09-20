package PBS::Types; 

use strict; 
use warnings FATAL => 'all'; 

use MooseX::Types -declare => [ qw( ID ) ];   
use MooseX::Types::Moose qw( Str ); 

subtype ID, as Str, where { /\d+(\.$ENV{HOSTNAME})?/ };  

1 
