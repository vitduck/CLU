package PBS::Bookmark; 

use Moose::Role;  
use MooseX::Types::Moose qw( HashRef ); 

use namespace::autoclean; 
use experimental qw( signatures ); 

has 'bookmark', ( 
    is        => 'ro', 
    isa       => HashRef,  
    lazy      => 1, 
    traits    => [ 'Hash' ], 
    init_arg  => undef, 
    builder   => '_build_bookmark', 
    handles   => { 
        has_bookmark => 'defined', 
        get_bookmark => 'get'
    } 
); 

sub delete_bookmark ( $self, $job ) { 
    unlink join '/', $self->get_bookmark( $job), 'OUTCAR' if  $self->has_bookmark( $job )
} 

1 
