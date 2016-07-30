package PBS::Qstat; 

# pragma
use autodie; 

# core
use IO::Pipe; 
use Term::ANSIColor; 

# cpan
use Moose::Role;  
use namespace::autoclean; 

# features
use experimental qw(signatures); 

# <attributes > 
has qstat => ( 
    is      => 'ro', 
    isa     => 'HashRef[Str]', 
    lazy    => 1, 
    builder => '_qstat_f', 
); 

has name => ( 
    is      => 'ro', 
    isa     => 'Str', 
    lazy    => 1, 
    default => sub ( $self ) { return $self->qstat->{name} }
); 

has owner => ( 
    is      => 'ro', 
    isa     => 'Str', 
    lazy    => 1, 
    default => sub ( $self ) { return $self->qstat->{'owner'} } 
); 

has server => ( 
    is      => 'ro', 
    isa     => 'Str', 
    lazy    => 1, 
    default => sub ( $self ) { return $self->qstat->{'server'} } 
); 

has state => ( 
    is      => 'ro', 
    isa     => 'Str', 
    lazy    => 1, 
    default => sub ( $self ) { return $self->qstat->{'state'} } 
); 

has queue => ( 
    is      => 'ro', 
    isa     => 'Str', 
    lazy    => 1, 
    default => sub ( $self ) { return $self->qstat->{'queue'} }
); 

has nodes => ( 
    is      => 'ro', 
    isa     => 'Str', 
    lazy    => 1, 
    default => sub ( $self ) { return $self->qstat->{'nodes'} } 
); 

has walltime => ( 
    is      => 'ro', 
    isa     => 'Str', 
    lazy    => 1, 
    default => sub ( $self ) { return $self->qstat->{'walltime'} }  
); 

has elapsed => ( 
    is       => 'ro', 
    isa      => 'Str', 
    lazy     => 1, 
    default  => sub ( $self ) { return $self->qstat->{'elapsed'} //= '' } 
); 

has init => ( 
    is       => 'ro', 
    isa      => 'Str', 
    lazy     => 1, 
    default  => sub ( $self ) { return $self->qstat->{'init'} } 
); 

# <methods> 
# parse the output of 'qstat -f JOB_ID'
sub _qstat_f ( $self ) { 
    my $id    = $self->id; 
    my $info  = {}; 
    my $qstat = IO::Pipe->new(); 
    
    $qstat->reader("qstat -f $id"); 
    while ( <$qstat> ) {  
        if    ( /job_name = (.*)/i                ) { $info->{name}     = $1 } 
        elsif ( /job_owner = (.*)@/i              ) { $info->{owner}    = $1 }
        elsif ( /server = (.*)/i                  ) { $info->{server}   = $1 } 
        elsif ( /job_state = (Q|R|C|E)/i          ) { $info->{state}    = $1 } 
        elsif ( /queue = (.*)/i                   ) { $info->{queue}    = $1 } 
        elsif ( /resource_list.nodes = (.*)/i     ) { $info->{nodes}    = $1 } 
        elsif ( /resource_list.walltime = (.*)/i  ) { $info->{walltime} = $1 } 
        elsif ( /resources_used.walltime = (.*)/i ) { $info->{elapsed}  = $1 } 
        # special case for init_work_dir 
        elsif ( /init_work_dir = (.*)/i           ) { 
            # single line 
            $info ->{init} = $1;  

            # for broken line
            # trim leading white space 
            chomp ( my $broken = <$qstat> );  
            $broken =~ s/^\s+//; 
            $info->{init} .= $broken; 
        }
    }

    return $info; 
} 

# kill job 
sub delete ( $self ) { system 'qdel', $self->id } 
    
1;
