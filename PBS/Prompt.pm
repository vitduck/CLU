package PBS::Prompt; 

use Moose::Role;  
use namespace::autoclean; 

use experimental 'signatures'; 

sub prompt ( $self, $method, $job ) { 
    printf "\n=> %s %s ? y/s [n] ", ucfirst( $method ), $job;  
    chomp ( my $reply = <STDIN> );  

    return 1 if $reply =~ /y|yes/i 
} 

1 
