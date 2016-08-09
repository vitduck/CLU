package PBS::Qstat; 

# pragma
use autodie; 
use warnings FATAL => 'all'; 

# core
use IO::Pipe; 
use Term::ANSIColor; 

# cpan
use Moose::Role;  
use namespace::autoclean; 

# features
use experimental qw(signatures); 

# PBS attributes 
my @pbs_attrs = qw(name owner server state queue nodes walltime elapsed init); 

# <attributes > 
has 'qstat', ( 
    is       => 'ro', 
    isa      => 'HashRef[Str]', 
    traits   => ['Hash'],
    lazy     => 1, 
    init_arg => undef,  

    default => sub ( $self ) { 
        my $id    = $self->id; 
        my $status  = {}; 
        my $qstat = IO::Pipe->new(); 

        $qstat->reader("qstat -f $id"); 
        while ( <$qstat> ) {  
            if    ( /job_name = (.*)/i                ) { $status->{name}     = $1 } 
            elsif ( /job_owner = (.*)@/i              ) { $status->{owner}    = $1 }
            elsif ( /server = (.*)/i                  ) { $status->{server}   = $1 } 
            elsif ( /job_state = (Q|R|C|E)/i          ) { $status->{state}    = $1 } 
            elsif ( /queue = (.*)/i                   ) { $status->{queue}    = $1 } 
            elsif ( /resource_list.nodes = (.*)/i     ) { $status->{nodes}    = $1 } 
            elsif ( /resource_list.walltime = (.*)/i  ) { $status->{walltime} = $1 } 
            elsif ( /resources_used.walltime = (.*)/i ) { $status->{elapsed}  = $1 } 
            elsif ( /init_work_dir = (.*)/i           ) { 
                # special case for init_work_dir 
                # single line 
                $status ->{init} = $1;  

                # for broken line
                # trim leading white space 
                chomp ( my $broken = <$qstat> );  
                $broken =~ s/^\s+//; 
                $status->{init} .= $broken; 
            }
        }

        # elapsed time can be undef if job has not started !  
        $status->{elapsed} //= '---'; 

        return $status; 
    }, 

    # currying delegation 
    handles => { map { $_ => [ get => $_ ] } @pbs_attrs } 
); 

sub status ( $self) { 
    my $header = $self->state eq 'R' ? 
    colored($self->id, 'bold underline blue') : 
    colored($self->id, 'bold underline red' ) ; 

    # print information from qstat
    printf "\n%s\n", $header;  
    for ( @pbs_attrs ) { printf "%-9s=> %s\n", ucfirst($_), $self->$_ }
}

1;
