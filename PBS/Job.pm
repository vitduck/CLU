package PBS::Job; 

use strictures 2; 
use namespace::autoclean; 
use Try::Tiny; 
use Moose::Role;  
use MooseX::Types::Moose qw( Str Int ArrayRef HashRef ); 
use PBS::Types qw( ID ); 
use experimental qw( signatures ); 

has 'user', ( 
    is        => 'ro', 
    isa       => Str, 
    lazy      => 1,
    default   => $ENV{USER}  
); 

has 'job', ( 
    is        => 'ro', 
    isa       => ArrayRef[ID],  
    traits    => [ 'Array' ], 
    lazy      => 1, 

    default   => sub ( $self ) { 
        return [ 
            $self->user eq '*' ? 
            sort { $a cmp $b } $self->get_all_jobs :  
            sort { $a cmp $b }
            map  $_->[0], 
            grep $_->[1]->{owner} eq $self->user, $self->get_qstatf
        ]
    }, 

    handles  => { 
        get_user_jobs => 'elements' 
    }
); 

sub delete_job ( $self, $job ) { 
    system 'qdel', $job if $self->user eq $ENV{USER}
} 

sub reset_job ( $self, $job ) { 
    $self->delete_job_bookmark( $job )
}

1 
