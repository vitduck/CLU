package PBS::Qstat; 

use Moose::Role;  
use IO::Pipe; 
use namespace::autoclean; 
use experimental qw( signatures ); 

has '_qstat', ( 
    is       => 'ro', 
    isa      => 'HashRef',  
    traits   => [ 'Hash' ],
    lazy     => 1, 
    init_arg => undef,  
    builder  => '_build_qstat', 
    handles  => { 
        validate_job => 'exists',  
        get_all_jobs => 'keys', 
        get_qstatf   => 'kv', 
    }
); 

sub _build_qstat ( $self ) { 
    my $qstat = {};  
    my $pipe  = IO::Pipe->new(); 

    $pipe->reader("qstat -f"); 
    while ( <$pipe> ) {  
        if ( /Job Id: (.*)/ ) { 
            my $id = $1; 
            $qstat->{$id} = {};  
            # use local version of $_ 
            while ( local $_ = <$pipe> ) {    
                if    ( /job_name = (.*)/i )                { $qstat->{$id}{name}     = $1 } 
                elsif ( /job_owner = (.*)@/i)               { $qstat->{$id}{owner}    = $1 }
                elsif ( /server = (.*)/i )                  { $qstat->{$id}{server}   = $1 } 
                elsif ( /job_state = (Q|R|C|E)/i )          { $qstat->{$id}{state}    = $1 } 
                elsif ( /queue = (.*)/i )                   { $qstat->{$id}{queue}    = $1 } 
                elsif ( /resource_list.nodes = (.*)/i )     { $qstat->{$id}{nodes}    = $1 } 
                elsif ( /resource_list.walltime = (.*)/i  ) { $qstat->{$id}{walltime} = $1 } 
                elsif ( /resources_used.walltime = (.*)/i ) { $qstat->{$id}{elapsed}  = $1 } 
                elsif ( /init_work_dir = (.*)/i ) { 
                    $qstat->{$id}{init} = $1;  
                    # for broken line
                    chomp ( my $broken_line = <$pipe> );  
                    $broken_line =~ s/^\s+//; 
                    $qstat->{$id}{init} .= $broken_line; 
                    # elapsed time can be undef if job has not started !  
                    $qstat->{$id}{elapsed} //= '---'; 
                    # go to next block
                    last 
                }
            }
        }
    }
    $pipe->close; 

    return $qstat; 
} 

1
