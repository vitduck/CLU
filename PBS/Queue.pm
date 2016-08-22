package PBS::Queue; 

# cpan  
use Moose; 
use namespace::autoclean; 

# pragma 
use autodie; 
use warnings FATAL => 'all'; 
use experimental qw(signatures);  

# Moose roles 
with qw(PBS::Qstat); 

# Moose methods 
sub BUILD ( $self, @args ) { 
    # populate of queue hash 
    $self->qstat_a; 
} 

# speed-up object construction 
__PACKAGE__->meta->make_immutable;

1; 
