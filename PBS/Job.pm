package PBS::Job; 

use strict;  
use warnings FATAL => 'all'; 
use namespace::autoclean; 

use Moose::Role;  
use MooseX::Types::Moose qw( Str Int ArrayRef ); 
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
        get_user_jobs => 'elements' 
    }
); 

sub qdel ( $self, $job ) { 
    system 'qdel', $job;  
} 

1 
