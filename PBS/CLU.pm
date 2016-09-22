package PBS::CLU;

use Moose; 
use MooseX::Types::Moose qw( Bool Str ArrayRef ); 

use PBS::Types qw( ID ); 

use namespace::autoclean; 
use experimental qw( signatures );  

with qw( PBS::Job ); 

has 'user', ( 
    is        => 'ro', 
    isa       => Str, 
    lazy      => 1,
    default   => $ENV{USER}  
); 

has 'job', ( 
    is        => 'ro', 
    isa       => ArrayRef[ ID ],  
    traits    => [ 'Array' ], 
    lazy      => 1, 
    predicate => 'has_job', 
    writer    => '_set_job', 
    builder   => '_build_job', 
    handles  => { 
        get_jobs => 'elements' 
    }
); 

has 'yes', ( 
    is        => 'rw', 
    isa       => Bool, 
    lazy      => 1, 
    writer    => 'set_yes', 
    default   => 0 
); 

has 'format', ( 
    is        => 'rw', 
    isa       => Str, 
    lazy      => 1, 
    writer    => 'set_format', 
    default   => ''
); 

has 'follow_symbolic', ( 
    is        => 'ro', 
    isa       => Bool, 
    lazy      => 1, 
    default   => 0, 
); 

sub BUILD ( $self, @ ) { 
    $self->_qstat; 

    if  ( $self->has_job ) { 
        $self->_set_job( 
            [ grep { $self->isa_job( $_ ) } map { s/(\d+).*$/$1/; $_ } $self->get_jobs ] 
        ) 
    }
} 

sub status ( $self ) { 
    for my $job ( $self->get_jobs ) {  
        $self->print_status( $job, $self->format )
    }
} 

sub delete ( $self ) { 
    for my $job ( $self->get_jobs ) {  
        $self->print_status( $job );   

        if ( $self->yes or $self->prompt('delete', $job) ) { 
            $self->qdel( $job ); 
            $self->delete_bootstrap( $job )
        }
    } 
} 

sub reset ( $self ) { 
    for my $job ( $self->get_jobs ) {  
        $self->print_status( $job );   

        if ( $self->yes or $self->prompt('reset', $job) ) { 
            $self->delete_bookmark( $job )
        } 
    } 
} 

sub prompt ( $self, $method, $job ) { 
    printf "\n=> %s %s ? y/s [n] ", ucfirst($method), $job;  
    chomp ( my $reply = <STDIN> );  

    return 1 if $reply =~ /y|yes/i 
} 

sub _build_job ( $self ) { 
    return [ 
        sort { $a cmp $b }
        map  $_->[0], 
        grep $_->[1]->{owner} eq $self->user, $self->get_qstatf
    ]
} 

__PACKAGE__->meta->make_immutable;

1
