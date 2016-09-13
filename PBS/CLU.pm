package PBS::CLU;

use strict; 
use warnings FATAL => 'all'; 
use namespace::autoclean; 

use Moose; 
use MooseX::Types::Moose qw( Bool ); 
with qw( PBS::Qstat PBS::Status ),  
     qw( PBS::Job PBS::Bootstrap PBS::Bookmark ),  
     qw( PBS::Prompt );  

use experimental qw( signatures );  

has 'yes', ( 
    is        => 'rw', 
    isa       => Bool, 
    lazy      => 1, 
    writer    => 'set_yes', 
    default   => 0 
); 

has 'follow_symbolic', ( 
    is        => 'ro', 
    isa       => Bool, 
    lazy      => 1, 
    default   => 0, 
); 

sub status ( $self ) { 
    for my $job ( $self->get_user_jobs ) {  
        $self->print_status( $job )
    }
} 

sub delete ( $self ) { 
    for my $job ( $self->get_user_jobs ) {  
        $self->print_status( $job );   

        if ( $self->yes or $self->prompt('delete', $job) ) { 
            $self->qdel( $job ); 
            $self->delete_bootstrap( $job )
        }
    } 
} 

sub reset ( $self ) { 
    for my $job ( $self->get_user_jobs ) {  
        $self->print_status( $job );   

        if ( $self->yes or $self->prompt('reset', $job) ) { 
            $self->remove_bookmark( $job )
        } 
    } 
} 

sub BUILD ( $self, @args ) { 
    # cache _qstat 
    $self->_qstat; 

    # use private writer to filter jobs
    if  ( $self->has_job ) { 
        $self->_set_job( [ grep $self->validate_job( $_ ), $self->get_user_jobs ] ) 
    }
} 

__PACKAGE__->meta->make_immutable;

1
