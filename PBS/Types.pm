package PBS::Types; 

# pragma
use autodie; 

# cpan
use MooseX::Types -declare => [ qw(ID) ];   
use MooseX::Types::Moose qw(Str); 

# features
use experimental qw(signatures); 

subtype ID, as Str, where { /\d+(\.$ENV{HOSTNAME})?/ };  

1; 
