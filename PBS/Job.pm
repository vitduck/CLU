package PBS::Job; 

use Moose::Role;  
use MooseX::Types::Moose qw( Undef Bool Str HashRef );  
use IO::Pipe; 
use File::Find; 
use File::Path qw( rmtree );  
use namespace::autoclean; 
use feature qw( switch );  
use experimental qw( signatures smartmatch );  

my @pbs_status = qw( owner name state queue nodes walltime elapsed init bootstrap bookmark );  

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
            'has_'.$attr => 'defined', 
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

has 'follow_symbolic', ( 
    is        => 'ro', 
    isa       => Bool, 
    lazy      => 1, 
    init_arg  => undef,
    default   => 0, 
); 

sub print_bookmark ( $self, $job ) { 
    if ( $self->has_bookmark( $job ) ) {  
        # trim the leading path 
        my $init     = $self->get_init( $job ); 
        my $bookmark = $self->get_bookmark( $job ) =~ s/$init\///r; 

        printf "%-9s=> %s\n", ucfirst( 'bookmark' ), $bookmark          
    }
} 

sub print_pbs_status ( $self, $attr, $job ) { 
    my $reader = 'get_'.$attr;  

    printf "%-9s=> %s\n", ucfirst( $attr ), $self->$reader( $job );  
} 

sub print_qstat ( $self, $job ) { 
    for ( @pbs_status ) { 
        when ( 'bootstrap' ) { next } 
        when ( 'bookmark'  ) { $self->print_bookmark( $job ) }
        default              { $self->print_pbs_status( $_, $job ) } 
    }
}  

sub delete ( $self, $job ) { 
    system 'qdel', $job;  
} 

sub reset ( $self, $job ) { 
    unlink join '/', $self->get_bookmark( $job), 'OUTCAR' if $self->has_bookmark( $job )
} 

sub clean ( $self, $job  ) { 
    rmtree $self->get_bootstrap( $job ) if $self->has_bootstrap( $job ) 
}

sub _set_bootstrap ( $self, $owner, $init ) { 
    return 
        $owner eq $ENV{ USER } 
        ? ( grep { -d and /bootstrap-\d+/ } glob "$init/*" )[0]
        : undef
} 

sub _set_bookmark ( $self, $owner, $init ) { 
    return 
        $owner eq $ENV{ USER } 
        ? do { 
            my %mod_time = ();   

            find { 
                wanted => sub { $mod_time{$File::Find::name} = -M if /OUTCAR/ }, 
                follow => $self->follow_symbolic 
            }, $init; 

            ( sort { $mod_time{ $a } <=> $mod_time{ $b } } keys %mod_time )[0] =~  s/\/OUTCAR//r 
        } 
        : undef
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
                if    ( /job_name = (.*)/i )                { $qstat->{ $id }{ name }      = $1 } 
                elsif ( /job_owner = (.*)@/i )              { $qstat->{ $id }{ owner }     = $1 }
                elsif ( /server = (.*)/i )                  { $qstat->{ $id }{ server }    = $1 }
                elsif ( /job_state = (Q|R|C|E)/i )          {  $qstat->{ $id }{ state }    = $1 } 
                elsif ( /queue = (.*)/i )                   {  $qstat->{ $id }{ queue }    = $1 } 
                elsif ( /resource_list.nodes = (.*)/i )     {  $qstat->{ $id }{ nodes }    = $1 } 
                elsif ( /resource_list.walltime = (.*)/i )  {  $qstat->{ $id }{ walltime } = $1 } 
                elsif ( /resources_used.walltime = (.*)/i ) {  $qstat->{ $id }{ elapsed }  = $1 } 
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

            $qstat->{ $id }{ bootstrap } = $self->_set_bootstrap( 
                $qstat->{ $id }->@{qw( owner init )} 
            ); 

            $qstat->{ $id }{ bookmark } = $self->_set_bookmark( 
                $qstat->{ $id }->@{qw(owner init )} 
            ); 
        }
    }
        
    $pipe->close; 

    return $qstat; 
}

1
