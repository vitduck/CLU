package PBS::Job;

# pragma 
use autodie; 
use warnings FATAL => 'all'; 

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

after delete => sub ( $self ) { 
    $self->clean; 
}; 

# simplify the constructor: ->new(ID) 
override BUILDARGS => sub ( $class, @args ) { 
    if ( @args == 1 and ID->check($args[0]) ) { return { id => $args[0] } } 

    return super; 
}; 

# <methods> 
sub one_line_info ( $self ) {  
    # depending on status of the job, print bookmark or init
    my $dir = $self->state eq "R" ? 
    $self->bookmark =~ s/$ENV{HOME}/~/r : 
    $self->init     =~ s/$ENV{HOME}/~/r; 

    printf "%s %s (%s)\n", $self->id, $dir , $self->state; 
} 

# parse output of qstatf -> set bootstrap -> set bookmark 
sub BUILD ( $self, @args ) { 
    $self->qstat;     
    $self->bootstrap; 
    $self->bookmark; 
}

# speed-up object construction 
__PACKAGE__->meta->make_immutable;

1; 
