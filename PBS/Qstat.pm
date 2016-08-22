package PBS::Qstat; 

# core
use IO::Pipe; 
use Term::ANSIColor; 

# cpan
use Moose::Role;  
use namespace::autoclean; 

# pragma
use autodie; 
use warnings FATAL => 'all'; 
use experimental qw(signatures); 

# PBS attributes 
my @pbs_attrs = qw(name owner server state queue nodes walltime elapsed init); 

# <attributes > 
has 'qstat_f', ( 
    is       => 'ro', 
    isa      => 'HashRef[Str]', 
    traits   => ['Hash'],
    lazy     => 1, 
    init_arg => undef,  

    default => sub ( $self ) { 
        my $status  = {}; 
        my $qstat = IO::Pipe->new(); 

        $qstat->reader("qstat -f ${\$self->id}"); 
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

        $qstat->close; 

        # elapsed time can be undef if job has not started !  
        $status->{elapsed} //= '---'; 

        return $status; 
    }, 

    # currying delegation 
    handles => { map { $_ => [ get => $_ ] } @pbs_attrs } 
); 

has 'qstat_a', ( 
    is       => 'ro', 
    isa      => 'HashRef[ArrayRef[Str]]', 
    traits   => ['Hash'],
    lazy     => 1, 
    init_arg => undef,  

    default  => sub ( $self ) { 
        my $queue = {}; 
        my $qstat = IO::Pipe->new(); 

        $qstat->reader("qstat -a"); 
        while ( <$qstat> ) { 
            if ( /\d+\.$ENV{HOSTNAME}/ ) { 
                my ( $id, $owner ) = split;  
                push $queue->{$owner}->@*, $id;  
            } 
        } 

        $qstat->close; 

        return $queue; 
    },  

    # currying delegation
    handles => { list_user_job => [ get => $ENV{USER} ] } 
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
