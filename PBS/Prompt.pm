package PBS::Prompt; 

# cpan
use Moose::Role;  
use namespace::autoclean; 

# pragma
use autodie; 
use warnings FATAL => 'all'; 
use experimental qw(signatures); 

# <methods> 
# ask for users consent before reset/delete job 
sub prompt ( $self, $task ) { 
    printf "\n=> %s %s ? y/s [n] ", ucfirst($task), $self->id; 
    if ( my $confirmation = <STDIN> =~ /y|yes/i ) { return 1 }  
} 

1; 
