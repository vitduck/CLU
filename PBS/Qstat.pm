package PBS::Qstat; 

use 5.010; 

use autodie; 
use File::Find; 
use IO::Pipe; 
use Moose::Role;  
use namespace::autoclean; 

sub _parse_qstat_f { 
    my ( $self ) = @_; 

    my $info     = {}; 
    my %mod_time = ();  

    # parse the output of 
    my $id    = $self->id; 
    my $qstat = IO::Pipe->new(); 
    $qstat->reader("qstat -f $id"); 

    # http://www.effectiveperlprogramming.com/2011/05/use-for-instead-of-given/
    while ( <$qstat> ) {  
        for ( $_ ) { 
            when ( /job_name = (.*)/i                ) { $info->{name}     = $1 } 
            when ( /job_owner = (.*)@/i              ) { $info->{owner}    = $1 }
            when ( /server = (.*)/i                  ) { $info->{server}   = $1 } 
            when ( /job_state = (Q|R|C|E)/i          ) { $info->{state}    = $1 } 
            when ( /queue = (.*)/i                   ) { $info->{queue}    = $1 } 
            when ( /resource_list.nodes = (.*)/i     ) { $info->{nodes}    = $1 } 
            when ( /resource_list.walltime = (.*)/i  ) { $info->{walltime} = $1 } 
            when ( /resources_used.walltime = (.*)/i ) { $info->{elapsed}  = $1 } 
            # special case for init_work_dir 
            when ( /init_work_dir = (.*)/i           ) { 
                # single line 
                $info ->{init} = $1;  

                # for broken line
                # trim leading white space 
                chomp ( my $broken = <$qstat> );  
                $broken =~ s/^\s+//; 
                $info->{init} .= $broken; 
            }
        }
    }

    # set bootstrap if calculation has started 
    ( $info->{bootstrap} ) = grep { -d and /bootstrap/ } glob "$info->{init}/*";
    $info->{bootstrap} //= ''; 
    
    # recursively find modified time of all OUTCAR in directory 
    # sort and extract the last modified one 
    find( sub { $mod_time{$File::Find::name} = -M if /OUTCAR/ }, $info->{init});
    $info->{latest} = (sort { $mod_time{$a} <=> $mod_time{$b} } keys %mod_time)[0]; 

    # trim 'OUTCAR' from filename 
    if ( $info->{latest} ) { 
        $info->{latest} =~ s/$info->{init}\/(.*)\/OUTCAR/$1/;  
    } else {  
        $info->{latest} = ''; 
    }

    return $info; 
} 

1;
