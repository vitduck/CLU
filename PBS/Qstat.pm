package PBS::Qstat; 

use IO::Pipe; 

use Moose::Role;  
use MooseX::Types::Moose qw( HashRef ); 

use namespace::autoclean; 
use experimental qw( signatures ); 

requires qw( _build_qstat );  

has '_qstat', ( 
    is       => 'ro', 
    isa      => HashRef,  
    traits   => [ 'Hash' ],
    lazy     => 1, 
    init_arg => undef,  
    builder  => '_build_qstat', 
    handles  => { 
        isa_job      => 'exists',  
        get_all_jobs => 'keys', 
        get_qstatf   => 'kv', 
    }
); 

sub _build_qstat ( $self ) { 
    my $qstat = {};  
    my $pipe  = IO::Pipe->new->reader("qstat -f");  

    while ( <$pipe> ) {  
        if ( /Job Id: (\d+)\..*$/ ) { 
            my $id = $1; 
            $qstat->{$id} = {};  
            # use local version of $_ 
            while ( local $_ = <$pipe> ) {    
                /job_name = (.*)/i                ?  $qstat->{$id}{name}     = $1 : 
                /job_owner = (.*)@/i              ?  $qstat->{$id}{owner}    = $1 :
                /server = (.*)/i                  ?  $qstat->{$id}{server}   = $1 : 
                /job_state = (Q|R|C|E)/i          ?  $qstat->{$id}{state}    = $1 : 
                /queue = (.*)/i                   ?  $qstat->{$id}{queue}    = $1 : 
                /resource_list.nodes = (.*)/i     ?  $qstat->{$id}{nodes}    = $1 : 
                /resource_list.walltime = (.*)/i  ?  $qstat->{$id}{walltime} = $1 : 
                /resources_used.walltime = (.*)/i ?  $qstat->{$id}{elapsed}  = $1 : 
                /init_work_dir = (.*)/i           ?  do {  
                    $qstat->{$id}{init} = $1;  

                    # for broken line
                    chomp ( my $broken_line = <$pipe> );  
                    $broken_line =~ s/^\s+//; 
                    $qstat->{$id}{init} .= $broken_line; 

                    # elapsed time can be undef if job has not started !  
                    $qstat->{$id}{elapsed} //= '---'; 

                    last 
                } :  
                next ; 
            }
        }
    }

    $pipe->close; 

    return $qstat; 
} 


1
