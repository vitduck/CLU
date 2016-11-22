package PBS::Job; 

use Moose::Role;  
use MooseX::Types::Moose 'ArrayRef';
use namespace::autoclean; 

use experimental 'signatures'; 

has 'job', ( 
    is        => 'rw', 
    isa       => ArrayRef,  
    traits    => [ 'Array' ], 
    init_arg  => undef,  
    handles   => { 
        add_job  => 'push', 
        get_jobs => 'elements'
    } 
); 

sub initialize ( $self, @jobs ) { 
    if ( @jobs ) { 
        $self->add_job( 
            grep { $self->isa_job( $_ ) }   # check from cached 
            map { s/(\d+).*$/$1/; $_ }      # strip the hostname 
            @jobs
        ); 
    } else { 
        my @jobs = sort { $a <=> $b } keys $self->qstat->%*; 
        $self->add_job( 
            $self->all_job
            ? @jobs          
            : grep $self->get_owner( $_) eq $self->get_user, @jobs 
        ); 
    } 
}

1
