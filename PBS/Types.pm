package PBS::Types; 

use strictures 2; 
use namespace::autoclean; 
use MooseX::Types -declare => [ qw( ID ) ];   
use MooseX::Types::Moose qw( Str ); 

subtype ID, as Str, where { /\d+(\.$ENV{HOSTNAME})?/ };  

1 
