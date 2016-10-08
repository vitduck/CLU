package PBS::Status; 

use Moose::Role;  
use MooseX::Types::Moose qw( HashRef ); 
use Term::ANSIColor; 
use namespace::autoclean; 
use feature qw( state switch );  
use experimental qw( signatures smartmatch );  

sub print_header ( $self, $job ) { 
    printf "\n%s\n", $self->color_header( $job ); 
}

sub print_status ( $self, $job, $format = 'default' ) { 
    given ( $format ) {  
        when ( 'oneline' ) { $self->print_status_oneline( $job ) }
        default            { $self->print_status_default( $job ) }
    }
}

sub print_status_oneline ( $self, $job ) { 
    state $count = 0;  

    my $dir =   
        $self->has_bookmark( $job )
        ? $self->get_bookmark( $job ) =~ s/.+?${ \$self->get_owner( $job ) }/~/r
        : $self->get_init( $job )     =~ s/.+?${ \$self->get_owner( $job ) }/~/r; 

    printf  
        "%02d. %s (%s) %-7s %s\n", 
        ++$count, 
        $self->color_header( $job ), 
        $self->get_elapsed( $job ), 
        $self->get_owner( $job ), 
        $dir  
} 

sub print_status_default ( $self, $job ) { 
    $self->print_header( $job ); 
    $self->print_qstat( $job ) 
} 

sub color_header ( $self, $job ) { 
    given ( $self->get_state( $job ) ) {  
        when ( /R/ ) { return colored( $job, 'bold blue' ) }
        when ( /Q/ ) { return colored( $job, 'bold red' )  }
        default      { return colored( $job, 'green' )     }
    } 
} 

1 
