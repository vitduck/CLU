package PBS::Job; 

use Moose::Role;  
use Term::ANSIColor; 
use File::Find; 
use namespace::autoclean; 
use feature qw( state switch );   
use experimental qw( signatures smartmatch );  

with qw( PBS::Qstat PBS::Qdel PBS::Bookmark PBS::Bootstrap ); 

my @attributes = qw( name owner state queue nodes walltime elapsed init );  

for my $attr ( @attributes ) { 
    has $attr, ( 
        is        => 'ro', 
        isa       => 'HashRef[Str]',  
        traits    => [ 'Hash' ], 
        lazy      => 1, 
        init_arg  => undef, 
        default   => sub { return { map { $_->[0] => $_->[1]{$attr} } $_[0]->get_qstatf } }, 
        handles   => { 'get_'.$attr => 'get' } 
    ); 
}

has 'header', ( 
    is        => 'ro', 
    isa       => 'HashRef', 
    traits    => [ 'Hash' ], 
    lazy      => 1, 
    init_arg  => undef, 
    builder   => '_build_header',  
    handles   => { get_header => 'get' } 
); 

sub color_header ( $self, $job ) { 
    given ( $self->get_state( $job ) ) {  
        when ( /R/ ) { return colored($job, 'bold blue') } 
        when ( /Q/ ) { return colored($job, 'bold red')  } 
        default { 
            # 'C' or 'E'

            colored($job, 'green' ); 
        } 
    } 
} 

sub print_header( $self, $job ) {
    printf "\n%s\n", $self->get_header( $job );
} 

sub print_bookmark ( $self, $job ) { 
    if ( $self->has_bookmark( $job ) ) {  
        # trim the leading path 
        my $init     = $self->get_init( $job ); 
        my $bookmark = $self->get_bookmark( $job ) =~ s/$init\///r; 

        printf "%-9s=> %s\n", ucfirst('bookmark'), $bookmark          
    }
} 

sub print_qstat ( $self, $job ) { 
    for my $attr ( @attributes) { 
        my $get_attr = 'get_'.$attr;  
        printf "%-9s=> %s\n", ucfirst($attr), $self->$get_attr( $job );  
    }
}  

sub print_status ( $self, $job, $format = '' ) { 
    given ( $format ) {  
        $self->print_status_oneline( $job ) when /oneline/; 

        default { 
            $self->print_header  ( $job ); 
            $self->print_qstat   ( $job );     
            $self->print_bookmark( $job )
        }
    }
}

sub print_status_oneline ( $self, $job ) { 
    state $count = 0;  

    my $dir = 
        $self->has_bookmark( $job ) ?  
        $self->get_bookmark( $job ) =~ s/$ENV{HOME}/~/r: 
        $self->get_init( $job )     =~ s/$ENV{HOME}/~/r; 

    printf
        "%02d. %s (%s) %s\n", 
        ++$count, $self->get_header( $job ), $self->get_elapsed( $job ), $dir  
} 

sub _build_header ( $self ) { 
    return { 
        map { $_ => $self->color_header( $_ ) } $self->get_user_jobs 
    }  
} 

sub _build_bootstrap ( $self ) { 
    my %bootstrap = (); 

    for my $job ( $self->get_user_jobs ) { 
        $bootstrap{$job} = (
            $self->get_owner( $job ) eq $ENV{USER} ?  
            ( grep { -d and /bootstrap-\d+/ } glob "${\$self->get_init( $job )}/*" )[0] :
            undef
        )
    }

    return \%bootstrap
} 

sub _build_bookmark ( $self ) { 
    my %bookmark = ();  

    for my $job ( $self->get_user_jobs ) { 
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

                    last 
                }
            }
        }
    }
    $pipe->close; 

    return $qstat; 
} 


1 
