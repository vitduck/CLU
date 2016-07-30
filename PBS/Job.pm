package PBS::Job;

use autodie; 
use Moose; 
use namespace::autoclean; 
use Term::ANSIColor; 

# roles 
with qw(PBS::Qstat PBS::Bootstrap PBS::Node); 

has id => ( 
    is       => 'ro', 
    isa      => 'Str', 
    required => 1 
); 

before reset => sub { 
    my ( $self ) = @_; 

    $self->info; 

    return; 
}; 

before delete => sub { 
    my ( $self ) = @_; 
    
    $self->info; 
    
    return; 
}; 

sub info { 
    my ( $self ) = @_; 

    # color the header based on job status 
    my $header; 
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

    return; 
}

1; 
