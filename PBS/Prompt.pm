package PBS::Prompt; 

# pragma
use autodie; 
use warnings FATAL => 'all'; 

# cpan
use Moose::Role;  
use namespace::autoclean; 

# features
use experimental qw(signatures); 

# <methods> 
# ask for users consent before reset/delete job 
sub prompt ( $self, $task ) { 
    printf "\n=> %s %s [yN]: ", ucfirst($task), $self->id; 
    if ( my $confirmation = <STDIN> =~ /y|yes/i ) { return 1 }  
} 

1; 
