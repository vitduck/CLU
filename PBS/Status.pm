package PBS::Status; 

use Moose::Role;  
use MooseX::Types::Moose qw( HashRef ); 
use namespace::autoclean; 

use Term::ANSIColor; 

use feature qw( state switch );  
use experimental qw( signatures smartmatch );  

requires qw( print_qstat );  
requires qw( has_bookmark get_bookmark );  
requires qw( get_owner get_state get_init get_elapsed );  

has 'header', ( 
    is        => 'ro', 
    isa       => HashRef, 
    traits    => [ qw( Hash ) ], 
    lazy      => 1, 
    init_arg  => undef, 
    builder   => '_build_header', 

    handles   => { 
        get_header => 'get' 
    } 
); 

sub print_header ( $self, $job ) { 
    printf "\n%s\n", $self->color_header( $job ); 
}

sub print_status ( $self, $job, $format = '' ) { 
    given ( $format ) {  
        when ( /oneline/ ) { $self->print_status_oneline( $job ) } 
        default            { $self->print_header( $job ); $self->print_qstat( $job ) }  
    }
}

sub print_status_oneline ( $self, $job ) { 
    state $count = 0;  

    my $dir = 
        $self->has_bookmark( $job ) 
        ? $self->get_bookmark( $job ) =~ s/$ENV{ HOME }/~/r 
        : $self->get_init( $job )     =~ s/$ENV{ HOME }/~/r; 

    printf 
        "%02d. %s %s ( %s ) %s\n", 
        ++$count, 
        $self->color_header( $job ), $self->get_owner( $job ), $self->get_elapsed( $job ), 
        $dir  
} 

sub color_header ( $self, $job ) { 
    given ( $self->get_state( $job ) ) {  
        when ( /R/ ) { return colored( $job, 'bold blue' ) } 
        when ( /Q/ ) { return colored( $job, 'bold red' ) } 
        default      { return colored( $job, 'green' ) } 
    } 
} 

1 
