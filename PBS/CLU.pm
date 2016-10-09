package PBS::CLU;

use Moose; 
use MooseX::Types::Moose qw( Bool Str ArrayRef HashRef );  
use PBS::Types qw( ID ); 
use File::Find; 
use namespace::autoclean; 
use experimental qw( signatures );   

extends 'PBS::Getopt'; 

with 'PBS::Prompt';  
with 'PBS::Job'; 
with 'PBS::Status'; 

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

sub delete_job ( $self ) { 
    for my $job ( $self->get_job_list ) {  
        $self->print_status( $job );   

        if ( $self->yes or $self->prompt( 'delete', $job ) ) { 
            $self->delete( $job ); 
            $self->clean( $job )
        }
    } 
} 

sub reset_job ( $self ) { 
    for my $job ( $self->get_job_list ) {  
        $self->print_status( $job );   

        if ( $self->yes or $self->prompt( 'reset', $job ) ) { 
            $self->reset( $job )
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

__PACKAGE__->meta->make_immutable;

1
