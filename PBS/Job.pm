package PBS::Job; 

use Moose::Role;  
use MooseX::Types::Moose qw( ArrayRef );
use namespace::autoclean; 

use experimental qw( signatures );  

requires 'isa_job'; 
requires 'get_owner'; 
requires 'get_user'; 
requires 'all_job'; 

has 'job', ( 
    is        => 'rw', 
    isa       => ArrayRef,  
    lazy      => 1, 
    init_arg  => undef,  
    builder   => '_build_job', 
    writer    => 'set_job',
); 

sub _build_job ( $self ) { 
    my @jobs = sort { $a <=> $b } keys $self->qstat->%*; 
    
    # return all job if --all is set
    return [ 
        $self->all_job 
        ? @jobs          
        : grep $self->get_owner( $_) eq $self->get_user, @jobs 
    ]
} 

# array accessor
sub get_jobs ( $self ) { 
    return ( 
        grep { $self->isa_job( $_ ) }   # check from cached 
        map { s/(\d+).*$/$1/; $_ }      # strip the hostname 
        $self->job->@*
    )
} 

1
