package PBS::Bootstrap;

use Moose::Role;  
use MooseX::Types::Moose qw( Undef Str HashRef ); 
use File::Path qw( rmtree ); 
use namespace::autoclean; 
use experimental qw( signatures ); 

requires qw( _build_bootstrap ); 

has 'bootstrap', ( 
    is        => 'ro', 
    isa       => HashRef[ Str | Undef ], 
    traits    => [ 'Hash' ], 
    lazy      => 1, 
    init_arg  => undef,
    builder   => '_build_bootstrap', 
    handles   => { 
        has_bootstrap => 'defined', 
        get_bootstrap => 'get'
    }
); 

sub delete_bootstrap ( $self, $job ) { 
    rmtree $self->get_bootstrap( $job ) if $self->has_bootstrap( $job ) 
} 

1 
