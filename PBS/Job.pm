package PBS::Job;

# core 
use File::Find; 
use File::Path qw(rmtree); 
use Term::ANSIColor; 

# cpan  
use Moose; 
use namespace::autoclean; 

# pragma 
use autodie; 
use warnings FATAL => 'all'; 
use experimental qw(signatures);  

# Moose types
use PBS::Types qw(ID); 

# Moose roles 
with qw(PBS::Qstat PBS::Prompt); 

# Moose attributes 
has 'id', ( 
    is        => 'ro', 
    isa       => ID, 
    required  => 1 
); 

has 'yes', ( 
    is        => 'ro', 
    isa       => 'Bool', 
); 

has 'follow_symbolic', ( 
    is        => 'ro', 
    isa       => 'Bool', 
    default   => 0, 
); 

has 'bootstrap', ( 
    is        => 'ro', 
    isa       => 'Str', 
    predicate => 'has_bootstrap', 
    lazy      => 1,   
    init_arg  => undef, 

    default   => sub ( $self ) { 
        return (grep { -d and /bootstrap-\d+/ } glob "${\$self->init}/*" )[0] 
    },    
); 

has 'bookmark', ( 
    is        => 'ro', 
    isa       => 'Str', 
    predicate => 'has_bookmark',
    lazy      => 1, 
    init_arg  => undef, 

    default   => sub ( $self ) { 
        my %mod_time = (); 

        find( { wanted => sub { $mod_time{$File::Find::name} = -M if /OUTCAR/ }, follow => $self->follow_symbolic }, 
                $self->init 
        ); 

        # current calculation directory 
        my $bookmark =  ( sort { $mod_time{$a} <=> $mod_time{$b} } keys %mod_time )[0] =~ s/\/OUTCAR//r; 

        # populate the history  
        if ( $bookmark ne $self->bootstrap ) { 
            $self->add_to_history($bookmark); 
        } 
        
        return $bookmark; 
    }, 
); 

has 'history', ( 
    is        => 'ro', 
    isa       => 'ArrayRef[Str]', 
    traits    => ['Array'], 
    lazy      => 1, 
    init_arg  => undef, 

    default   => sub { ['---'] }, 
    handles   => { add_to_history => 'unshift' }, 
); 

# Moose modifiers 
after status => sub ( $self ) { 
    if ( $self->has_bookmark ) { 
        printf "%-9s=> %s\n", ucfirst('bookmark'), $self->bookmark =~ s/${\$self->init}\///r;  
        printf "%-9s=> %s\n", ucfirst('previous'), $self->history->[0] =~ s/${\$self->init}\///r;  
    } 
}; 

# Moose methods
# delete and clean bootstrap directory 
sub delete ( $self ) { 
    $self->status; 

    if ( $self->yes or $self->prompt('delete') ) { 
        system 'qdel', $self->id;  
        if ( $self->has_bootstrap ) { rmtree $self->bootstrap }
    }
} 

# reset job by deleting latest OUTCAR  
sub reset ( $self ) { 
    $self->status; 

    if ( $self->yes or $self->prompt('reset') ) { 
        if ( $self->has_bookmark ) { unlink join '/', $self->bookmark, 'OUTCAR' }
    }
}

sub status_oneline ( $self ) {  
    # depending on status of the job, print bookmark or init
    my $dir = $self->has_bootstrap ? 
    $self->bookmark =~ s/$ENV{HOME}/~/r : 
    $self->init     =~ s/$ENV{HOME}/~/r; 

    printf "%s %s (%s)\n", $self->id, $dir , $self->state; 
} 

# simplify the constructor: ->new(id) 
override BUILDARGS => sub ( $class, @args ) { 
    if ( @args == 1 and ID->check($args[0]) ) { return { id => $args[0] } } 

    return super; 
}; 

# parse output of qstatf -> set bootstrap -> set bookmark 
sub BUILD ( $self, @args ) { 
    # populate the status of job 
    $self->qstat_f;     

    # owner of the job is also the user who runs the scripts 
    if ( $self->owner eq $ENV{USER} ) { 
        $self->bootstrap; 
        $self->bookmark; 
    }
}

# speed-up object construction 
__PACKAGE__->meta->make_immutable;

1; 
