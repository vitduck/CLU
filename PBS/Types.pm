package PBS::Types; 

use Moose::Role; 
use Moose::Util::TypeConstraints;
use namespace::autoclean; 

subtype 'ID', as 'Str', where { /\d+(\.$ENV{HOSTNAME})?/ }; 

1 
