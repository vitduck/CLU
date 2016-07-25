package Job;

use 5.010; 

use autodie; 
use File::Path qw/rmtree/; 
use Moose; 
use namespace::autoclean; 

with 'Qstat', 'User';  

my @attributes  = qw/id name owner server state 
                    queue nodes walltime elapsed 
                    init current
                    /; 

has id => ( 
    is       => 'ro', 
    isa      => 'Str', 
    required => 1, 
); 

has qstat => ( 
    traits  => ['Hash'],
    is      => 'ro', 
    isa     => 'HashRef[Str]', 
    lazy    => 1, 

    builder => '_build_qstatf', 

    # currying delegation
    handles => { 
        map { $_ => [ get => $_ ] } 
        qw/name owner server state queue nodes walltime init/
    }, 
); 

has elapsed => ( 
    is      => 'ro', 
    isa     => 'Str', 
    lazy    => 1, 
    builder => '_build_qstata', 
); 

has bootstrap => ( 
    is      => 'ro', 
    isa     => 'Str', 
    lazy    => 1, 
    builder => '_build_bootstrap', 
); 

has current => ( 
    is      => 'ro', 
    isa     => 'Str', 
    lazy    => 1, 
    builder => '_build_current', 
); 

sub info { 
    my ( $self ) = @_; 
    
    printf "\n"; 
    for my $attr ( @attributes ) { 
        printf "%-10s> %s\n", ucfirst($attr), $self->$attr;  
    }
      
    return; 
}

sub delete { 
    my ( $self ) = @_; 

    # display information 
    $self->info; 

    # confirmation 
    printf "\n=> qdel: delete job %s? ", $self->id; 
    chomp ( my $answer = <STDIN> );  

    # job deletion with qdel 
    if ( $answer =~ /^y/i ) { 
        # kill job 
        system 'qdel', $self->id;  

        # delete bootstrap dir 
        rmtree $self->bootstrap; 
    }  

    return; 
}

sub reset { 
    my ( $self ) = @_; 

    $self->info; 

    # short-circuit 
    if ( $self->state eq 'Q' ) { return } 

    # only reset if inside bootstrap 
    if ( $self->current ne 'bootstrap' ) { return } 

    # confirmation  
    printf "\n=> Reset %s? ", $self->id; 
    chomp ( my $answer = <STDIN> ); 

    # delete OUTAR  
    if ( $answer =~ /^y/i ) { unlink join '/', $self->init, $self->current, 'OUTCAR' }
    
    return; 
} 

1;
