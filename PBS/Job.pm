package PBS::Job; 

use Term::ANSIColor; 

use Moose::Role;  
use MooseX::Types::Moose qw( Str ArrayRef HashRef ); 

use PBS::Types qw( ID ); 

use namespace::autoclean; 
use feature qw( state switch );   
use experimental qw( signatures smartmatch );  

requires qw( get_qstatf ); 
requires qw( get_bookmark ); 

has 'job', ( 
    is        => 'ro', 
    isa       => ArrayRef[ ID ],  
    traits    => [ 'Array' ], 
    lazy      => 1, 
    predicate => 'has_job', 
    writer    => '_set_job', 
    default   => sub ( $self ) {  
        return [ 
            sort { $a cmp $b }
            map  $_->[0], 
            grep $_->[1]->{owner} eq $self->user, $self->get_qstatf
        ]
    },  
    handles  => { 
        get_jobs => 'elements' 
    }
); 

has 'header', ( 
    is        => 'ro', 
    isa       => HashRef, 
    traits    => [ 'Hash' ], 
    lazy      => 1, 
    init_arg  => undef, 
    default   => sub ($self ) { 
        return { map { $_ => $_[0]->color_header( $_ ) } $self->get_jobs } 
    }, 
    handles   => { 
        get_header => 'get' 
    } 
); 

my @attributes = qw( name owner state queue nodes walltime elapsed init );  
for my $attr ( @attributes ) { 
    has $attr, ( 
        is        => 'ro', 
        isa       => HashRef[Str],  
        traits    => [ 'Hash' ], 
        lazy      => 1, 
        init_arg  => undef, 
        default   => sub ( $self ) { 
            return { map { $_->[0] => $_->[1]{$attr} } $self->get_qstatf } 
        }, 
        handles   => { 
            'get_'.$attr => 'get' 
        } 
    ); 
}

sub color_header ( $self, $job ) { 
    given ( $self->get_state( $job ) ) {  
        when ( /R/ ) { return colored( "< $job >", 'bold blue' ) } 
        when ( /Q/ ) { return colored( "< $job >", 'bold red'  ) } 
        default      { return colored( "< $job >", 'green' )     } 
    } 
} 

sub print_status ( $self, $job, $format = '' ) { 
    given ( $format ) {  
        when ( /oneline/ ) { $self->print_status_oneline( $job ) } 
        default            { 
            $self->print_header  ( $job ); 
            $self->print_qstat   ( $job );     
            $self->print_bookmark( $job )
        }
    }
}

sub print_header( $self, $job ) {
    printf "\n%s\n", $self->get_header( $job );
} 

sub print_qstat ( $self, $job ) { 
    for my $attr ( @attributes ) { 
        my $reader = 'get_'.$attr;  
        printf "%-9s=> %s\n", ucfirst($attr), $self->$reader( $job );  
    }
}  

sub print_bookmark ( $self, $job ) { 
    if ( $self->has_bookmark( $job ) ) {  
        # trim the leading path 
        my $init     = $self->get_init( $job ); 
        my $bookmark = $self->get_bookmark( $job ) =~ s/$init\///r; 

        printf "%-9s=> %s\n", ucfirst('bookmark'), $bookmark          
    }
} 

sub print_status_oneline ( $self, $job ) { 
    state $count = 0;  

    my $dir = 
        $self->has_bookmark( $job ) ?  
        $self->get_bookmark( $job ) =~ s/$ENV{HOME}/~/r: 
        $self->get_init( $job )     =~ s/$ENV{HOME}/~/r; 

    printf
        "%02d. %s ( %s ) %s\n", 
        ++$count, $self->get_header( $job ), $self->get_elapsed( $job ), $dir  
} 

1 
