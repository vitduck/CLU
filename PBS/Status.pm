package PBS::Status; 

use strictures 2; 
use namespace::autoclean; 
use Term::ANSIColor; 
use Moose::Role;  
use MooseX::Types::Moose qw( Str ArrayRef HashRef ); 
use experimental qw( signatures ); 

my @attributes = qw( owner state queue nodes walltime elapsed init );  

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

has 'status_header', ( 
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

sub print_job_status ( $self, $job ) { 
    # header 
    printf "\n%s\n", $self->get_header( $job );

    # basic PBS 
    for my $attr ( @attributes) { 
        # basic PBS attirbutes  
        my $get_attr = 'get_'.$attr;  
        printf "%-9s=> %s\n", ucfirst($attr), $self->$get_attr( $job );  
    }
    
    # extended PBS 
    $self->print_job_bookmark( $job )
}

1 
