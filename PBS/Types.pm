package PBS::Types; 

use strict; 
use warnings; 

use MooseX::Types::Moose 'Str';  
use MooseX::Types -declare => [ qw/ID/ ]; 

subtype ID, as Str, where { /\d+(\.$ENV{ HOSTNAME })?/ }; 

1
