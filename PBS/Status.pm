package PBS::Status; 

use strict; 
use warnings FATAL => 'all'; 
use namespace::autoclean; 

use Term::ANSIColor; 
use Moose::Role;  
use MooseX::Types::Moose qw( Str ArrayRef HashRef ); 

use experimental qw( signatures ); 

my @attributes = qw( owner state queue nodes walltime elapsed init );  

# install basic PBS attributes and accessor 
for my $attr ( @attributes ) { 
    has $attr, ( 
        is        => 'ro', 
        isa       => HashRef[Str],  
        traits    => [ 'Hash' ], 
        lazy      => 1, 
        init_arg  => undef, 

        default   => sub ( $self ) { 
            return { map  { $_->[0] => $_->[1]{$attr} } $self->get_qstatf } 
        }, 

        handles   => { 
            'get_'.$attr => 'get', 
        } 
    ); 
}

# colorized status headder 
has 'header', ( 
    is        => 'ro', 
    isa       => HashRef, 
    traits    => [ 'Hash' ], 
    lazy      => 1, 
    init_arg  => undef, 

    default   => sub ( $self ) { 
       return { 
           map {
               $_ => 
                    $self->get_state( $_ ) eq 'R' ? 
                    colored($_, 'bold underline blue') : 
                    colored($_, 'bold underline red' ) ; 
            } 
           $self->get_user_jobs 
       }  
    }, 

    handles   => { 
        get_header => 'get' 
    } 
); 

sub print_header( $self, $job ) {
    printf "\n%s\n", $self->get_header( $job );
} 

sub print_qstat ( $self, $job ) { 
    for my $attr ( @attributes) { 
        my $get_attr = 'get_'.$attr;  
        printf "%-9s=> %s\n", ucfirst($attr), $self->$get_attr( $job );  
    }
}  

sub print_status ( $self, $job ) { 
    $self->print_header  ( $job ); 
    $self->print_qstat   ( $job );     
    $self->print_bookmark( $job )
}

1 
