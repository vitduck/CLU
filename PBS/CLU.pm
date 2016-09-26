package PBS::CLU;

use File::Find; 

use Moose; 
use MooseX::Types::Moose qw( Bool Str ); 

use namespace::autoclean; 
use experimental qw( signatures );  

with qw( PBS::Qstat PBS::Qdel ); 
with qw( PBS::Bookmark PBS::Bootstrap ); 
with qw( PBS::Job ); 

has 'user', ( 
    is        => 'ro', 
    isa       => Str, 
    lazy      => 1,
    default   => $ENV{USER}  
); 

has 'yes', ( 
    is        => 'rw', 
    isa       => Bool, 
    lazy      => 1, 
    writer    => 'set_yes', 
    default   => 0 
); 

has 'format', ( 
    is        => 'rw', 
    isa       => Str, 
    lazy      => 1, 
    writer    => 'set_format', 
    default   => ''
); 

has 'follow_symbolic', ( 
    is        => 'ro', 
    isa       => Bool, 
    lazy      => 1, 
    default   => 0, 
); 

sub BUILD ( $self, @ ) { 
    $self->qstat; 

    if  ( $self->has_job ) { 
        $self->_set_job( 
            [ grep { $self->isa_job( $_ ) } map { s/(\d+).*$/$1/; $_ } $self->get_jobs ] 
        ) 
    }
} 

sub status ( $self ) { 
    for my $job ( $self->get_jobs ) {  
        $self->print_status( $job, $self->format )
    }
} 

sub delete ( $self ) { 
    for my $job ( $self->get_jobs ) {  
        $self->print_status( $job );   

        if ( $self->yes or $self->prompt('delete', $job) ) { 
            $self->qdel( $job ); 
            $self->delete_bootstrap( $job )
        }
    } 
} 

sub reset ( $self ) { 
    for my $job ( $self->get_jobs ) {  
        $self->print_status( $job );   

        if ( $self->yes or $self->prompt('reset', $job) ) { 
            $self->delete_bookmark( $job )
        } 
    } 
} 

sub prompt ( $self, $method, $job ) { 
    printf "\n=> %s %s ? y/s [n] ", ucfirst($method), $job;  
    chomp ( my $reply = <STDIN> );  

    return 1 if $reply =~ /y|yes/i 
} 

# PBS::Qstat 
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

# PBS::Bootstrap 
sub _build_bootstrap ( $self ) { 
    my %bootstrap = (); 

    for my $job ( $self->get_jobs ) { 
        $bootstrap{$job} = (
            $self->get_owner( $job ) eq $ENV{USER} ?  
            ( grep { -d and /bootstrap-\d+/ } glob "${\$self->get_init( $job )}/*" )[0] :
            undef
        )
    }

    return \%bootstrap
} 

# PBS::Bookmark 
sub _build_bookmark ( $self ) { 
    my %bookmark = ();  

    for my $job ( $self->get_jobs ) { 
        $bookmark{$job} = ( 
            $self->get_owner( $job ) eq $ENV{USER} ?  
            do { 
                my %mod_time = ();   
                find { 
                    wanted => sub { $mod_time{$File::Find::name} = -M if /OUTCAR/ }, 
                    follow => $self->follow_symbolic 
                }, $self->get_init( $job );  
                # trim OUTCAR from full path
                ( sort { $mod_time{$a} <=> $mod_time{$b} } keys %mod_time )[0] =~ s/\/OUTCAR//r; 
            } : 
            undef
        )
    }

    return \%bookmark; 
} 

__PACKAGE__->meta->make_immutable;

1
