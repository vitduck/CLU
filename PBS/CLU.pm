package PBS::CLU;

use strictures 2; 
use namespace::autoclean; 
use Moose; 
use MooseX::Types::Moose qw( Bool Str ); 
with qw( PBS::Qstat PBS::Status ),  
     qw( PBS::Job PBS::Bootstrap PBS::Bookmark ),  
     qw( PBS::Prompt );  

use experimental qw( signatures );  

has 'yes', ( 
    is        => 'ro', 
    isa       => Bool, 
    lazy      => 1, 
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
        $self->print_job_status( $job )
    }
} 

sub delete ( $self ) { 
    for my $job ( $self->get_user_jobs ) {  
        $self->print_job_status( $job );   
        if ( $self->yes or $self->prompt('delete', $job) ) { 
            $self->delete_job( $job ); 
            $self->delete_job_bootstrap( $job )
        }
    } 
} 

sub reset ( $self ) { 
    for my $job ( $self->get_user_jobs ) {  
        $self->print_job_status( $job );   
        if ( $self->yes or $self->prompt('reset', $job) ) { 
            $self->reset_job( $job )
        } 
    } 
} 

sub BUILD ( $self, @args ) { 
    $self->_qstat; 
} 

__PACKAGE__->meta->make_immutable;

1
