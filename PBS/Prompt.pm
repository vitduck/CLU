package PBS::Prompt; 

# pragma
use autodie; 

# cpan
use Moose::Role;  
use namespace::autoclean; 

# features
use experimental qw(signatures); 

# <methods> 
# ask for users consent before reset/delete job 
sub prompt ( $self, $task ) { 
    printf "\n=> %s %s [yN]: ", ucfirst($task), $self->id; 

    my $confirmation = <STDIN>; 
    if ( $confirmation =~ /y|yes/i ) { 
        return 1; 
    }
} 

1; 
