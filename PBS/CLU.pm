package PBS::CLU;

use Moose; 
use MooseX::Types::Moose qw( Bool Str ArrayRef HashRef );  
use PBS::Types qw( ID ); 
use File::Find; 
use namespace::autoclean; 
use experimental qw( signatures );   

extends qw( PBS::Getopt );  

with qw( PBS::Prompt );  
with qw( PBS::Qstat PBS::Qdel ); 
with qw( PBS::Bookmark PBS::Bootstrap ); 
with qw( PBS::Status );  

has 'job_list', ( 
    is        => 'ro', 
    isa       => ArrayRef,  
    traits    => [ 'Array' ], 
    lazy      => 1, 
    init_arg  => undef,  
    builder   => '_build_job_list', 
    handles   => { 
        get_job_list => 'elements' 
    }, 
); 

sub BUILD ( $self, @ ) { 
    $self->qstat; 
} 

sub status ( $self ) { 
    for my $job ( $self->get_job_list ) {  
        $self->print_status( $job, $self->get_format )
    }
} 

sub delete ( $self ) { 
    for my $job ( $self->get_job_list ) {  
        $self->print_status( $job );   

        if ( $self->yes or $self->prompt( 'delete', $job ) ) { 
            $self->qdel( $job ); 
            $self->delete_bootstrap( $job )
        }
    } 
} 

sub reset ( $self ) { 
    for my $job ( $self->get_job_list ) {  
        $self->print_status( $job );   

        if ( $self->yes or $self->prompt( 'reset', $job ) ) { 
            $self->delete_bookmark( $job )
        } 
    } 
} 

sub _build_job_list ( $self ) { 
    return [
        $self->has_job 
        ? do {  
            grep { $self->isa_job( $_ ) }   # check from cached 
            map { s/(\d+).*$/$1/; $_ }      # strip the hostname 
            split /,/, $self->get_job       # turn string to list 
        }
        : do { 
            my @jobs = sort { $a <=> $b } $self->get_jobs; 
            
            # return all job if --all is set
            $self->all
            ? @jobs          
            : grep $self->get_owner( $_) eq $self->get_user, @jobs 
        }
    ]
} 

sub _build_bootstrap ( $self ) { 
    my %bootstrap = (); 
    
    for my $job ( $self->get_job_list ) { 
        $bootstrap{ $job } = (
            $self->get_owner( $job ) eq $ENV{USER}
            ? ( grep { -d and /bootstrap-\d+/ } glob "${ \$self->get_init( $job ) }/*" )[0]
            : undef
        )
    }

    return \%bootstrap
} 

sub _build_bookmark ( $self ) { 
    my %bookmark = (); 

    for my $job ( $self->get_job_list ) { 
        $bookmark{ $job } = ( 
            $self->get_owner( $job ) eq $ENV{USER}
            ? do { 
                my %mod_time = ();   

                find { 
                    wanted => sub { $mod_time{$File::Find::name} = -M if /OUTCAR/ }, 
                    follow => $self->follow_symbolic 
                }, $self->get_init( $job );  

                # trim OUTCAR from the full path
                ( sort { $mod_time{ $a } <=> $mod_time{ $b} } keys %mod_time )[0] =~ s/\/OUTCAR//r; 
            } 
            : undef
        )
    }

    return \%bookmark
} 


__PACKAGE__->meta->make_immutable;

1
