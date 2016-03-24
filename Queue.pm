package Queue; 

use strict; 
use warnings; 
use Carp qw/croak/; 
use IO::Pipe; 

# constructor 
sub new { 
    my ( $class ) = @_; 

    # bless ref 
    my $self = {}; 
    bless $self => $class; 

    # init 
    $self->_init; 

    return  $self; 
} 

# initializer 
sub _init { 
    my ( $self ) = @_; 

    # pipe to qstat -a 
    my $qstat = IO::Pipe->new(); 
    $qstat->reader("qstat -a"); 
    
    while ( <$qstat> ) { 
        # skip blank line 
        if ( /^\s+$/ ) { next } 

        # skip header
        if ( /$ENV{HOSTNAME}:|Job ID|Elap|^-+/ ) { next }

        # hash initialiazation 
        my ( $id, $user ) = (split)[0,1]; 
        
        # strip the hostname from job id 
        #$id =~ s/(^\d+)(.*)$/$1/;  

        $self->{$id} = $user; 
    }
    
    return; 
}

# get job by a user 
sub get_job_list { 
    my ( $self, $user ) = @_;  
    my @jobs = (); 
    
    # return jobs belonging to specific user 
    if ( $user ) { 
        @jobs = grep { $self->{$_} eq $user } keys %$self;  
    # returns all jobs 
    } else { 
        @jobs = keys %$self; 
    }

    return sort @jobs; 
}

1; 
