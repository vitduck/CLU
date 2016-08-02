package PBS::Job;

# pragma 
use autodie; 

# core 
use Term::ANSIColor; 

# cpan  
use Moose; 
use namespace::autoclean; 

# features  
use experimental qw(signatures);  

# <types> 
use PBS::Types qw(ID); 

# <roles> 
with qw(PBS::Qstat PBS::Qdel PBS::Bootstrap PBS::Bookmark); 

# <attributes> 
has 'id', ( 
    is       => 'ro', 
    isa      => ID, 
    required => 1 
); 

# <modifiers> 
before [ qw(reset delete) ] => sub ( $self ) { 
    $self->info 
}; 

after 'delete' => sub ( $self ) { 
    $self->clean; 
}; 

# speed-up object construction 
__PACKAGE__->meta->make_immutable;

1; 
