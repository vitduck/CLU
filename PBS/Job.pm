package PBS::Job;

use 5.010; 

use autodie; 
use File::Path qw/rmtree/; 
use Moose; 
use namespace::autoclean; 
use Term::ANSIColor;

# roles 
with 'PBS::Qstat'; 

my @attributes = 
qw/name owner server state queue nodes walltime elapsed init latest bootstrap/; 

has id => ( 
    is       => 'ro', 
    isa      => 'Str', 
    required => 1, 
); 

# for currying delegation 
has _qstat => ( 
    traits   => ['Hash'],
    is       => 'ro', 
    isa      => 'HashRef[Str]', 
    lazy     => 1, 
    builder  => '_parse_qstat_f', 
    init_arg => undef, 
    handles => { map { $_ => [ get => $_ ] } @attributes }, 
); 

sub info { 
    my ( $self ) = @_; 

    my $head = $self->state eq 'R' ? 
    colored($self->id, 'bold underline blue') : 
    colored($self->id, 'bold underline red'); 

    printf "\n%s\n", $head;  
    for my $attr ( @attributes ) { 
        if ( $attr eq 'bootstrap' ) { next }  
        if ( $self->$attr ) { printf "%-10s> %s\n", ucfirst($attr), $self->$attr }; 
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
        if ( $self->bootstrap ) { rmtree $self->bootstrap }  
    }  

    return; 
}

sub reset { 
    my ( $self ) = @_; 

    $self->info; 

    # short-circuit 
    if ( $self->state eq 'Q' ) { return } 

    # confirmation  
    printf "\n=> Reset %s? ", $self->id; 
    chomp ( my $answer = <STDIN> ); 

    # delete OUTAR  
    if ( $answer =~ /^y/i ) { unlink join '/', $self->init, $self->latest, 'OUTCAR' }
    
    return; 
} 

1;
