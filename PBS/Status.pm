package PBS::Status; 

use Moose::Role;  
use MooseX::Types::Moose 'HashRef'; 
use Term::ANSIColor; 

use namespace::autoclean; 
use feature qw/state switch/;  
use experimental qw/signatures smartmatch/;  

with 'PBS::Format'; 

sub print_status ( $self, $job, $format = 'default' ) { 
    given ( $format ) {  
        when ( 'oneline' ) { $self->print_status_oneline( $job ) }
        default            { $self->print_status_default( $job ) }
    }
}

sub print_status_default ( $self, $job ) { 
    $self->print_header  ( $job ); 
    $self->print_qstat   ( $job );  
    $self->print_bookmark( $job )
} 

sub print_status_oneline ( $self, $job ) { 
    state $count  = 0;  
    my $max_level = 7; 

    my $name_format    = $self->get_print_format( 'name'    ); 
    my $owner_format   = $self->get_print_format( 'owner'   ); 
    my $node_format    = $self->get_print_format( 'nodes'   ); 
    my $elapsed_format = $self->get_print_format( 'elapsed' ); 

    # bootstrap
    my $dir = 
        $self->has_bookmark( $job ) 
        ? $self->get_bookmark( $job )
        : $self->get_init    ( $job ); 

    # debug 
    $dir =~ s/.+?${ \$self->get_owner( $job ) }/~/ unless $self->has_debug; 

    # nested directory 
    my @dirs = split /\//, $dir; 
    $dir = join( '/', '..', @dirs[ $#dirs-$max_level .. $#dirs ] ) 
        if ! $self->has_debug && @dirs > $max_level; 

    printf  
        "%02d. %s %-${name_format} %-${owner_format} %-${node_format} %-${elapsed_format} %s\n", 
        ++$count, 
        $self->color_header( $job ), 
        $self->get_name    ( $job ), 
        $self->get_owner   ( $job ), 
        $self->get_nodes   ( $job ), 
        $self->get_elapsed ( $job ), 
        $dir  
} 

sub print_header ( $self, $job ) { 
    printf "\n%s\n", $self->color_header( $job ); 
}

sub color_header ( $self, $job ) { 
    given ( $self->get_state( $job ) ) {  
        when ( /R/ ) { return colored( $job, 'bold blue' ) }
        when ( /Q/ ) { return colored( $job, 'bold red' )  }
        default      { return colored( $job, 'green' )     }
    } 
} 

1 
