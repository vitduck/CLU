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

# <roles> 
with qw(PBS::Qstat PBS::Bootstrap PBS::Node); 

# <attributes> 
has id => ( 
    is       => 'ro', 
    isa      => 'Str', 
    required => 1 
); 

# <modifiers> 
before reset  => sub ( $self) { $self->info }; 
before delete => sub ( $self) { $self->info }; 

# <methods>
sub info ( $self) { 
    my $header; 
    
    # color the header based on job status 
    if ( $self->state eq 'R' ) { 
        $header = colored($self->id, 'bold underline blue')
    } else { 
        $header = colored($self->id, 'bold underline red' ) 
    } 

    # print information from qstat
    printf "\n%s\n", $header;  
    for ( qw/name owner server state queue nodes walltime elapsed init node/ ) {  
        if ( $self->$_ ) { printf "%-9s> %s\n", ucfirst($_), $self->$_ };
    }
}

1; 
