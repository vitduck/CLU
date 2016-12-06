package PBS::CLU;

use File::Find; 

use Moose; 
use PBS::Types qw/ID/; 
use namespace::autoclean; 

use experimental qw/signatures/;  

extends qw/PBS::Getopt/;  

with qw/PBS::Prompt/;  
with qw/PBS::Qstat PBS::Qdel/;  
with qw/PBS::Job PBS::Status/;  
with qw/PBS::Bookmark PBS::Bootstrap/;  

sub BUILD ( $self, @ ) { 
    $self->qstat; 
} 

sub status ( $self ) { 
    for my $job ( $self->get_jobs ) {  
        $self->print_status( $job, $self->get_format )
    }
} 

sub delete ( $self ) { 
    for my $job ( $self->get_jobs ) {  
        $self->print_status( $job );   

        if ( $self->yes or $self->prompt( 'delete', $job ) ) { 
            $self->qdel( $job ); 
            $self->delete_bootstrap( $job )
        }
    } 
} 

sub reset ( $self ) { 
    for my $job ( $self->get_jobs ) {  
        $self->print_status( $job );   

        if ( $self->yes or $self->prompt( 'reset', $job ) ) { 
            $self->delete_bookmark( $job )
        } 
    } 
} 

__PACKAGE__->meta->make_immutable;

1
