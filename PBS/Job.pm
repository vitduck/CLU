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

# <methods> 
sub one_line_info ( $self ) {  
    if ( $self->state eq "R" ) { 
        printf "%s %s (%s)\n", $self->id, $self->bookmark =~ s/$ENV{HOME}/~/r, $self->state; 
    } else { 
        printf "%s %s (%s)\n", $self->id, $self->init =~ s/$ENV{HOME}/~/r, $self->state; 
    } 
} 

# speed-up object construction 
__PACKAGE__->meta->make_immutable;

1; 
