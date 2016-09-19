package PBS::Status; 

use strict; 
use warnings FATAL => 'all'; 
use namespace::autoclean; 
use feature qw( switch );

use Term::ANSIColor; 
use Moose::Role;  
use MooseX::Types::Moose qw( Str ArrayRef HashRef ); 

use feature qw( state switch ); 
use experimental qw( signatures smartmatch ); 

# install basic PBS attributes and accessor 
my @attributes = qw( name owner state queue nodes walltime elapsed init );  

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
        return { map { $_ => $self->color_header( $_ ) } $self->get_user_jobs }  
    }, 

    handles   => { 
        get_header => 'get' 
    } 
); 

sub color_header ( $self, $job ) { 
    given ( $self->get_state( $job ) ) {  
        return colored($job, 'bold blue') when /R/;  
        return colored($job, 'bold red')  when /Q/;  
        # 'C' or 'E'
        default { 
            colored($job, 'green' ); 
        } 
    } 
} 

sub print_header( $self, $job ) {
    printf "\n%s\n", $self->get_header( $job );
} 

sub print_qstat ( $self, $job ) { 
    for my $attr ( @attributes) { 
        my $get_attr = 'get_'.$attr;  
        printf "%-9s=> %s\n", ucfirst($attr), $self->$get_attr( $job );  
    }
}  

sub print_status ( $self, $job, $format = '' ) { 
    given ( $format ) {  
        $self->print_status_oneline( $job ) when /oneline/; 

        default { 
            $self->print_header  ( $job ); 
            $self->print_qstat   ( $job );     
            $self->print_bookmark( $job )
        }
    }
}

sub print_status_oneline ( $self, $job ) { 
    state $count = 0;  

    my $dir = 
        $self->has_bookmark( $job ) ?  
        $self->get_bookmark( $job ) =~ s/$ENV{HOME}/~/r : 
        $self->get_init( $job )     =~ s/$ENV{HOME}/~/r; 

    printf "%02d. %s (%s) %s\n", 
        ++$count, 
        $self->get_header( $job ), $self->get_elapsed( $job ), $dir  
} 

1 
