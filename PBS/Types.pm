package PBS::Types; 

# cpan
use MooseX::Types -declare => [ qw(ID) ];   
use MooseX::Types::Moose qw(Str); 

# pragma
use autodie; 
use warnings FATAL => 'all'; 

subtype ID, as Str, where { /\d+(\.$ENV{HOSTNAME})?/ };  

1; 
