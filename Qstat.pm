package Qstat; 

use 5.010; 

use autodie; 
use IO::Pipe; 
use Moose::Role;  
use namespace::autoclean; 

sub _build_qstatf { 
    my ( $self ) = @_; 

    my $info = {}; 

    # parse the output of 
    my $id    = $self->id; 
    my $qstat = IO::Pipe->new(); 
    $qstat->reader("qstat -f $id"); 

    # regex table
    my %regex = ( 
        name     => qr/job_name = (.*)/i, 
        owner    => qr/job_owner = (.*)@/i, 
        server   => qr/server = (.*)/i, 
        state    => qr/job_state = (Q|R|C|E)/i, 
        queue    => qr/queue = (.*)/i, 
        nodes    => qr/resource_list.nodes = (.*)/i, 
        walltime => qr/resource_list.walltime = (.*)/i, 
    ); 

    # iterate over regrex 
    while ( <$qstat> ) { 
        for my $attr ( keys %regex ) {  
            # interpolate the regex 
            if ( /$regex{$attr}/ ) { 
                $info->{$attr} = $1; 
                last; 
            }
        } 
        # special handle for init_dir 
        if ( /init_work_dir = (.*)/i )          { 
            # single line 
            $info ->{init} = $1;  
            # broken line 
            chomp ( my $broken = <$qstat> );  
            if ( $broken ) { 
                # trim leading white space 
                $broken =~ s/^\s+//; 
                # join broken part 
                $info->{init} .= $broken; 
            }
        } 
    } 

    return $info; 
} 

sub _build_qstata { 
    my ( $self ) = @_; 
    
    my $id    = $self->id; 
    my $qstat = IO::Pipe->new(); 
    $qstat->reader("qstat -a"); 

    while ( <$qstat> ) { 
        # skip blank line 
        if ( /^\s+$/ ) { next } 
        if ( /$ENV{HOSTNAME}:|Job ID|Elap|^-+/ ) { next }
        
        if ( /^$id/ ) { return  (split)[-1] }  
    } 
}

1;
