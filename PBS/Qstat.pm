package PBS::Qstat; 

use Moose::Role;  
use MooseX::Types::Moose qw( Undef Str HashRef );  
use IO::Pipe; 
use namespace::autoclean; 
use feature qw( switch );  
use experimental qw( signatures smartmatch );  

my @pbs_status = qw( owner name state queue nodes walltime elapsed init ); 

# automatically install pbs attributes
for my $attr ( @pbs_status ) {
    has $attr, ( 
        is        => 'ro', 
        isa       => HashRef[ Str | Undef ],  
        traits    => [ 'Hash' ], 
        lazy      => 1, 
        init_arg  => undef, 
        default   => sub ( $self ) { 
            return { map { $_->[0] => $_->[1]{$attr} } $self->get_qstatf } 
        }, 
        handles   => { 
            'get_'.$attr => 'get' 
        } 
    ); 
}

has 'qstat', ( 
    is       => 'ro', 
    isa      => HashRef,  
    traits   => [ 'Hash' ],
    lazy     => 1, 
    init_arg => undef,  
    builder  => '_build_qstat', 
    handles  => { 
        isa_job    => 'exists',  
        get_jobs   => 'keys', 
        get_qstatf => 'kv', 
    }
); 

sub print_qstat ( $self, $job ) { 
    for my $attr ( @pbs_status ) { 
        my $reader = 'get_'.$attr;  
        
        printf "%-9s=> %s\n", ucfirst( $attr ), $self->$reader( $job );  
    } 
}

sub _build_qstat ( $self ) { 
    my $qstat = {};  
    my $pipe  = IO::Pipe->new->reader("qstat -f");  

    while ( <$pipe> ) {  
        if ( /Job Id: (\d+)\..*$/ ) { 
            my $id = $1; 
            $qstat->{ $id } = {};  

            # basic PBS status 
            while ( local $_ = <$pipe> ) {    
                if    ( /job_name = (.*)/i )                { $qstat->{ $id }{ name }     = $1 } 
                elsif ( /job_owner = (.*)@/i )              { $qstat->{ $id }{ owner }    = $1 }
                elsif ( /server = (.*)/i )                  { $qstat->{ $id }{ server }   = $1 }
                elsif ( /job_state = (Q|R|C|E)/i )          { $qstat->{ $id }{ state }    = $1 } 
                elsif ( /queue = (.*)/i )                   { $qstat->{ $id }{ queue }    = $1 } 
                elsif ( /resource_list.nodes = (.*)/i )     { $qstat->{ $id }{ nodes }    = $1 } 
                elsif ( /resource_list.walltime = (.*)/i )  { $qstat->{ $id }{ walltime } = $1 } 
                elsif ( /resources_used.walltime = (.*)/i ) { $qstat->{ $id }{ elapsed }  = $1 } 
                elsif ( /init_work_dir = (.*)/i ) { 
                    $qstat->{ $id }{ init } = $1;  

                    # for broken line
                    chomp ( my $broken_line = <$pipe> );  
                    $broken_line =~ s/^\s+//; 
                    $qstat->{ $id }{ init } .= $broken_line; 

                    # elapsed time can be undef if job has not started !  
                    $qstat->{ $id }{ elapsed } //= '---'; 

                    last 
                }  
            }
        }
    }
        
    $pipe->close; 

    return $qstat; 
}

1
