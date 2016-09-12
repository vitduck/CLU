package PBS::Prompt; 

use strictures 2; 
use namespace::autoclean; 
use Moose::Role;  
use experimental qw(signatures); 

sub prompt ( $self, $method, $job ) { 
    printf "\n=> %s %s ? y/s [n] ", ucfirst($method), $job;  
    if ( my $confirmation = <STDIN> =~ /y|yes/i ) { 
        return 1 
    }  
} 

1 
