package PBS::Qstat; 

use autodie; 
use strict; 
use warnings FATAL => 'all'; 
use namespace::autoclean; 

use IO::Pipe; 

use Moose::Role;  
use MooseX::Types::Moose qw( HashRef ); 

use experimental qw( signatures ); 

# <attributes > 
has '_qstat', ( 
    is       => 'ro', 
    isa      => HashRef,  
    traits   => [ 'Hash' ],
    lazy     => 1, 
    init_arg => undef,  

    default => sub ( $self ) { 
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
                        # special case for init_work_dir 
                        # single line 
                        $qstat->{$id}{init} = $1;  

                        # for broken line
                        # trim leading white space 
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
    }, 

    handles   => { 
        validate_job => 'exists',  
        get_all_jobs => 'keys', 
        get_qstatf   => 'kv', 
    }
); 

1
