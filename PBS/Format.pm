package PBS::Format; 

use Moose::Role;  
use MooseX::Types::Moose qw( HashRef Str ); 
use List::Util qw( max ); 
use namespace::autoclean; 

use experimental qw( signatures );  

has 'print_format', ( 
    is        => 'ro', 
    isa       => HashRef,  
    traits    => [ 'Hash' ], 
    init_arg  => undef, 
    lazy      => 1, 
    builder   => '_build_print_format', 
    handles   => { 
        get_print_format => 'get'
    }
); 

sub _build_print_format ( $self ) { 
    my %format = ( 
        owner   => join( '', $self->_max_attr_length( 'owner' ), 's' ), 
        elapsed => join( '', $self->_max_attr_length( 'elapsed' ), 's' ), 
    ); 

    return \%format; 
} 

sub _max_attr_length ( $self, $attr ) { 
    return max( map length( $_->{owner} ), values $self->qstat->%* ); 
} 

1
